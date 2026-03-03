output "apigw_invoke_url" {
  description = "API gateway invoke url"
  value       = module.api.invoke_url
}

output "region" {
  description = "AWS region where the main resouces are created"
  value       = var.region
}
