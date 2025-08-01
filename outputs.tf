output "api_gateway_url" {
  description = "API Gateway endpoint URL"
  value       = "${aws_api_gateway_stage.main.invoke_url}/message"
}

output "sqs_queue_url" {
  description = "SQS queue URL"
  value       = aws_sqs_queue.main.url
}

output "sqs_queue_arn" {
  description = "SQS queue ARN"
  value       = aws_sqs_queue.main.arn
}

output "sns_topic_arn" {
  description = "SNS topic ARN"
  value       = aws_sns_topic.notification.arn
}

output "producer_lambda_function_name" {
  description = "Producer Lambda function name"
  value       = aws_lambda_function.producer.function_name
}

output "consumer_lambda_function_name" {
  description = "Consumer Lambda function name"
  value       = aws_lambda_function.consumer.function_name
}

output "dead_letter_queue_url" {
  description = "Dead letter queue URL"
  value       = aws_sqs_queue.dead_letter.url
}

output "api_gateway_rest_api_id" {
  description = "API Gateway REST API ID"
  value       = aws_api_gateway_rest_api.main.id
} 