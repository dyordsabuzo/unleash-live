module "auth" {
  source          = "../modules/cognito"
  test_user_email = var.test_user_email
  test_user_repo  = var.test_user_repo
}
