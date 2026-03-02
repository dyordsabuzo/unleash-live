module "auth" {
  source          = "../modules/cognito"
  test_user_email = var.test_user_email
}


resource "aws_sns_topic" "sns" {
  name = "my-sns-topic"
}
