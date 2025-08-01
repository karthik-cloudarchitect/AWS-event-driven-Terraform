# Event-Driven Architecture: API Gateway → Lambda → SQS → SNS (Terraform)

This repository contains the Terraform implementation of an event-driven architecture using AWS services.

## Architecture Overview

```
Client → API Gateway → Lambda → SQS → Lambda → SNS → Subscribers
```

## Components

- **API Gateway**: Receives HTTP requests
- **Lambda (Producer)**: Processes requests and sends messages to SQS
- **SQS**: Queues messages for asynchronous processing
- **Lambda (Consumer)**: Processes SQS messages and publishes to SNS
- **SNS**: Publishes notifications to subscribers

## Prerequisites

- AWS CLI configured
- Terraform installed (version >= 1.0)
- Python 3.8+

## Project Structure

```
event-driven-terraform/
├── README.md
├── requirements.txt
├── main.tf
├── variables.tf
├── outputs.tf
├── providers.tf
├── src/
│   ├── producer/
│   │   └── lambda_function.py
│   └── consumer/
│       └── lambda_function.py
└── tests/
    ├── test_producer.py
    └── test_consumer.py
```

## Deployment

### Using Terraform CLI

1. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Plan the deployment:
   ```bash
   terraform plan
   ```

4. Deploy the infrastructure:
   ```bash
   terraform apply
   ```

### Using Terraform Cloud

1. Connect your repository to Terraform Cloud
2. Configure variables in Terraform Cloud
3. Run terraform apply through the web interface

## Testing

Run the tests:
```bash
pytest tests/
```

## Features

- Asynchronous message processing
- Dead letter queue for failed messages
- Comprehensive error handling
- CORS support
- Detailed logging and monitoring
- Terraform state management

## Cleanup

```bash
terraform destroy
```

## API Endpoints

- `POST /message` - Send message to SQS queue

## Monitoring

- CloudWatch Logs for Lambda functions
- SQS metrics and alarms
- SNS delivery status 