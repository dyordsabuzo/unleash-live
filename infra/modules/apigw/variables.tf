variable "cognito_user_pool_name" {
  description = "Cognito user pool name"
  type        = string
}

variable "endpoint_configs" {
  description = "List of rest api endpoints"
  type = list(object({
    path_part = string
    methods   = list(string)
  }))
}

variable "lambda_invoke_arns" {
  description = "Lambda function invoke arns"
  type        = map(string)
}

variable "environment" {
  description = "Environment name for the infrastructure stack"
  type        = string
  default     = "prod"
}

variable "apigw_timeout_milliseconds" {
  description = "Timeout for apigw integration in ms"
  type        = number
  default     = 60000
}
