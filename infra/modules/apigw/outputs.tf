output "invoke_url" {
  description = "API gateway stage invoke URL"
  value       = aws_api_gateway_stage.stage.invoke_url
}
