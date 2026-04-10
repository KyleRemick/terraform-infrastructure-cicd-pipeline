terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region for dev environment."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project identifier for naming and tags."
  type        = string
  default     = "terraform-infrastructure-cicd-pipeline"
}

variable "bucket_name" {
  description = "Globally unique S3 bucket name for dev."
  type        = string
}

module "sample_infra" {
  source = "../../modules/sample_infra"

  project_name  = var.project_name
  environment   = "dev"
  bucket_name   = var.bucket_name
  force_destroy = true
  tags = {
    tier = "development"
  }
}

output "dev_bucket_name" {
  value       = module.sample_infra.bucket_name
  description = "S3 bucket name deployed in dev."
}
