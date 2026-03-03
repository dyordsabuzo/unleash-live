variable "region" {
  description = "The AWS region where the resources will be deployed."
  type        = string

  validation {
    condition     = contains(["us-east-1", "eu-west-1"], var.region)
    error_message = "⚠️ The region must be one of: ['us-east-1', 'eu-west-1']"
  }
}

variable "environment" {
  description = "Environment name for the infrastructure stack"
  type        = string
  default     = "prod"
}

variable "cognito_region" {
  description = "AWS region where cognito is set"
  type        = string
}

variable "cognito_user_pool_name" {
  description = "Cognito user pool name"
  type        = string
}

variable "sns_topic_arn" {
  description = "The ARN of the SNS Topic"
  type        = string
}

variable "dynamodb_table_name" {
  description = "The name of the DynamoDB table"
  type        = string
}
