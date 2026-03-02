variable "region" {
  description = "AWS region to create resources in"
  type        = string
}

variable "cluster" {
  description = "ECS cluster properties"
  type = object({
    name                      = string
    enable_container_insights = optional(bool)
  })
}

variable "task_family" {
  description = "ECS task family"
  type        = string
}

variable "network_mode" {
  description = "ECS network mode"
  type        = string
  default     = "awsvpc"
}

variable "launch_type" {
  description = "ECS launch type"
  type = object({
    type   = string
    cpu    = number
    memory = number
  })
  default = {
    type   = "FARGATE"
    cpu    = 256
    memory = 512
  }
}

variable "sns_topic_arn" {
  description = "ARN of the SNS topic to publish messages to"
  type        = string
}
