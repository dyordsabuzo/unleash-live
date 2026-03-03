data "archive_file" "archive" {
  for_each    = { for function in var.function_config : function.name => function }
  type        = "zip"
  source_file = "${path.module}/scripts/${each.value.filename}"
  output_path = "${path.module}/scripts/${each.value.name}.zip"
}

data "aws_ssm_parameter" "candidate_email" {
  name            = "/cognito/testuser/EMAIL"
  with_decryption = true
  provider        = aws.cognito
}

data "aws_ssm_parameter" "candidate_repo" {
  name            = "/cognito/testuser/REPO"
  with_decryption = true
  provider        = aws.cognito
}
