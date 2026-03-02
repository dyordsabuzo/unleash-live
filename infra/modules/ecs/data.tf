data "aws_iam_policy_document" "ecs_task_assume_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

#tfsec:ignore:aws-iam-no-policy-wildcards:exp:2026-02-01
data "aws_iam_policy_document" "task_execution_permissions" {
  statement {
    effect = "Allow"
    resources = [
      "arn:aws:sns:*",
    ]
    actions = [
      "sns:Publish",
    ]
  }
}

# get default vpc
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

data "aws_ssm_parameter" "candidate_email" {
  name            = "/cognito/testuser/EMAIL"
  with_decryption = true
}

data "aws_ssm_parameter" "candidate_repo" {
  name            = "/cognito/testuser/REPO"
  with_decryption = true
}
