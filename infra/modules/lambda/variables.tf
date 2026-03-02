variable "function_config" {
  description = "Lambda function configuration"
  type = list(object({
    name        = string
    description = string
    filename    = string
    handler     = string
    runtime     = string
    timeout     = number
    environment = optional(map(string))
  }))
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name"
  type        = string
}

variable "region" {
  description = "The AWS region where the resources will be deployed."
  type        = string
  default     = "us-east-1"
}

variable "sns_topic_arn" {
  description = "The ARN of the SNS topic"
  type        = string
}

variable "ecs_task_definition_arn" {
  description = "Dispatcher ecs task definition arn"
  type        = string
}

variable "ecs_cluster_arn" {
  description = "Dispatcher ecs cluster arn"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "ECS task role arn"
  type        = string
}
