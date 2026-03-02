# Amazon Cognito User Pool
resource "aws_cognito_user_pool" "pool" {
  name = "auth-user-pool"

  # Configure sign-in using email
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  # Configure email delivery (using Cognito default for simplicity)
  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  # Define a password policy
  password_policy {
    minimum_length    = 10
    require_uppercase = true
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
  }

  # Enable admin creation of users without requiring an immediate password change
  admin_create_user_config {
    allow_admin_create_user_only = true
  }
}

# User Pool Client
resource "aws_cognito_user_pool_client" "client" {
  name                = "auth-user-pool-client"
  user_pool_id        = aws_cognito_user_pool.pool.id
  generate_secret     = false
  read_attributes     = ["email", "preferred_username"]
  write_attributes    = ["email", "preferred_username"]
  explicit_auth_flows = ["ADMIN_NO_SRP_AUTH", "USER_PASSWORD_AUTH"]
}

resource "random_password" "testuser" {
  length           = 10
  override_special = "_+,.@:/-"
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
}

resource "aws_ssm_parameter" "testuser_email" {
  name  = "/cognito/testuser/EMAIL"
  type  = "String"
  value = var.test_user_email

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "testuser_password" {
  name  = "/cognito/testuser/PASSWORD"
  type  = "SecureString"
  value = random_password.testuser.result

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "testuser_repo" {
  name  = "/cognito/testuser/REPO"
  type  = "String"
  value = "UNSET"

  lifecycle {
    ignore_changes = [value]
  }
}

# Test user
resource "aws_cognito_user" "test_user" {
  count        = var.test_user_email != null ? 1 : 0
  user_pool_id = aws_cognito_user_pool.pool.id
  username     = var.test_user_email # Use the personal email as the username
  password     = aws_ssm_parameter.testuser_password.value

  attributes = {
    email          = var.test_user_email
    email_verified = true
  }

  force_alias_creation = true
}
