# Data sources
data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# SQS Dead Letter Queue
resource "aws_sqs_queue" "dead_letter" {
  name = "${var.environment}-dlq"
  
  tags = {
    Name = "${var.environment}-dlq"
  }
}

# SQS Main Queue
resource "aws_sqs_queue" "main" {
  name = "${var.environment}-message-queue"
  
  visibility_timeout_seconds = var.sqs_visibility_timeout
  message_retention_period  = var.sqs_message_retention_period
  
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter.arn
    maxReceiveCount     = var.sqs_max_receive_count
  })
  
  tags = {
    Name = "${var.environment}-message-queue"
  }
}

# SNS Topic
resource "aws_sns_topic" "notification" {
  name = "${var.environment}-notification-topic"
  
  tags = {
    Name = "${var.environment}-notification-topic"
  }
}

# IAM Role for Producer Lambda
resource "aws_iam_role" "producer_lambda_role" {
  name = "${var.environment}-producer-lambda-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Role for Consumer Lambda
resource "aws_iam_role" "consumer_lambda_role" {
  name = "${var.environment}-consumer-lambda-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for Producer Lambda
resource "aws_iam_role_policy" "producer_lambda_policy" {
  name = "${var.environment}-producer-lambda-policy"
  role = aws_iam_role.producer_lambda_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage"
        ]
        Resource = aws_sqs_queue.main.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# IAM Policy for Consumer Lambda
resource "aws_iam_role_policy" "consumer_lambda_policy" {
  name = "${var.environment}-consumer-lambda-policy"
  role = aws_iam_role.consumer_lambda_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = aws_sqs_queue.main.arn
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = aws_sns_topic.notification.arn
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Archive producer Lambda function
data "archive_file" "producer_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/src/producer"
  output_path = "${path.module}/producer_lambda.zip"
}

# Archive consumer Lambda function
data "archive_file" "consumer_lambda" {
  type        = "zip"
  source_dir  = "${path.module}/src/consumer"
  output_path = "${path.module}/consumer_lambda.zip"
}

# Producer Lambda Function
resource "aws_lambda_function" "producer" {
  filename         = data.archive_file.producer_lambda.output_path
  function_name    = "${var.environment}-producer-function"
  role            = aws_iam_role.producer_lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory_size
  
  environment {
    variables = {
      QUEUE_URL = aws_sqs_queue.main.url
    }
  }
  
  tags = {
    Name = "${var.environment}-producer-function"
  }
}

# Consumer Lambda Function
resource "aws_lambda_function" "consumer" {
  filename         = data.archive_file.consumer_lambda.output_path
  function_name    = "${var.environment}-consumer-function"
  role            = aws_iam_role.consumer_lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = var.lambda_runtime
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory_size
  
  environment {
    variables = {
      SNS_TOPIC_ARN = aws_sns_topic.notification.arn
    }
  }
  
  tags = {
    Name = "${var.environment}-consumer-function"
  }
}

# SQS Event Source Mapping for Consumer Lambda
resource "aws_lambda_event_source_mapping" "consumer_sqs" {
  event_source_arn = aws_sqs_queue.main.arn
  function_name    = aws_lambda_function.consumer.function_name
  batch_size       = 1
}

# API Gateway
resource "aws_api_gateway_rest_api" "main" {
  name = "${var.environment}-event-driven-api"
  
  tags = {
    Name = "${var.environment}-event-driven-api"
  }
}

# API Gateway Resource
resource "aws_api_gateway_resource" "message" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "message"
}

# API Gateway Method
resource "aws_api_gateway_method" "post" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.message.id
  http_method   = "POST"
  authorization = "NONE"
}

# API Gateway Integration
resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.message.id
  http_method = aws_api_gateway_method.post.http_method
  
  integration_http_method = "POST"
  type                   = "AWS_PROXY"
  uri                    = aws_lambda_function.producer.invoke_arn
}

# Lambda Permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.producer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.main.execution_arn}/*/*"
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "main" {
  depends_on = [
    aws_api_gateway_integration.lambda
  ]
  
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = var.environment
}

# API Gateway Stage
resource "aws_api_gateway_stage" "main" {
  deployment_id = aws_api_gateway_deployment.main.id
  rest_api_id   = aws_api_gateway_rest_api.main.id
  stage_name    = var.environment
} 