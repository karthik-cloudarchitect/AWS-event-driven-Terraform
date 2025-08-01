terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
  
  backend "s3" {
    # Uncomment and configure for remote state storage
    # bucket = "your-terraform-state-bucket"
    # key    = "event-driven-architecture/terraform.tfstate"
    # region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "event-driven-architecture"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
} 