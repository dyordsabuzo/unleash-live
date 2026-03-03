data "aws_cognito_user_pools" "pools" {
  name     = var.cognito_user_pool_name
  provider = aws.cognito
}
