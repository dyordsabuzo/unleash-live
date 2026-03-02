output "user_pool_id" {
  description = "The ID of the Cognito User Pool"
  value       = module.auth.user_pool_id
}

output "user_pool_arn" {
  description = "The arn of the Cognito User Pool"
  value       = module.auth.user_pool_arn
}

output "user_pool_client_id" {
  description = "The ID of the Cognito User Pool Client"
  value       = module.auth.user_pool_client_id
}

output "sns_topic_arn" {
  description = "The ARN of the SNS Topic"
  value       = aws_sns_topic.sns.arn
}

output "cognito_region" {
  description = "Region where cognito resources are created"
  value       = var.region
}
