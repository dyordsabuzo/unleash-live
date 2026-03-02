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

variable "test_user_email" {
  description = "Email address for the test user"
  type        = string
  sensitive   = true
}
