terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.cognito] # Maps to passed provider
    }
  }
}

# API Gateway
resource "aws_api_gateway_rest_api" "api" {
  name        = "unleash-live-rest-api"
  description = "Unleash Live secured API"
}

# endpoints
resource "aws_api_gateway_resource" "endpoints" {
  for_each    = { for ec in var.endpoint_configs : ec.path_part => ec }
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = each.key
}

# authorizer
resource "aws_api_gateway_authorizer" "cognito_auth" {
  name          = "cognito-authorizer"
  type          = "COGNITO_USER_POOLS"
  rest_api_id   = aws_api_gateway_rest_api.api.id
  provider_arns = data.aws_cognito_user_pools.pools.arns
}

# method requests and authorization
resource "aws_api_gateway_method" "method_requests" {
  for_each      = local.path_method_list
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.endpoints[each.value.path_part].id
  http_method   = each.value.method
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_auth.id
}

# integration requests
resource "aws_api_gateway_integration" "integration_requests" {
  for_each                = local.path_method_list
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.endpoints[each.value.path_part].id
  http_method             = each.value.method
  integration_http_method = "POST"
  type                    = "AWS"
  uri                     = lookup(var.lambda_invoke_arns, each.value.path_part, "")
  timeout_milliseconds    = var.apigw_timeout_milliseconds
}

# method response
resource "aws_api_gateway_method_response" "method_responses" {
  for_each    = local.path_method_list
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.endpoints[each.value.path_part].id
  http_method = aws_api_gateway_method.method_requests[each.key].http_method
  status_code = "200"

  //cors section
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# integration response
resource "aws_api_gateway_integration_response" "integration_responses" {
  for_each    = local.path_method_list
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.endpoints[each.value.path_part].id
  http_method = each.value.method
  status_code = aws_api_gateway_method_response.method_responses[each.key].status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'${each.value.method},OPTIONS'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_integration.integration_requests
  ]
}

# deployment
resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeployment = sha1(jsonencode(concat(
      [for e in aws_api_gateway_resource.endpoints : e.id],
      [for m in aws_api_gateway_method.method_requests : m.id],
      [for r in aws_api_gateway_method_response.method_responses : r.id],
      [for i in aws_api_gateway_integration.integration_requests : i.id],
      [for j in aws_api_gateway_integration_response.integration_responses : j.id],
    )))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# stage
resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = var.environment
}

# lambda permission
resource "aws_lambda_permission" "apigw_lambda" {
  for_each      = var.lambda_invoke_arns
  statement_id  = "AllowExecutionFromAPIGateway-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.key
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*/*"
}
