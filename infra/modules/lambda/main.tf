# dynamodb table
resource "aws_dynamodb_table" "table" {
  name           = var.dynamodb_table_name
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "id"

  attribute {
    name = "id"
    type = "S"
  }
}

# lambda role
resource "aws_iam_role" "role" {
  name = "lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# lambda function
resource "aws_lambda_function" "function" {
  for_each         = { for function in var.function_config : function.name => function }
  function_name    = each.value.name
  description      = each.value.description
  filename         = data.archive_file.archive[each.key].output_path
  handler          = each.value.handler
  runtime          = each.value.runtime
  source_code_hash = data.archive_file.archive[each.key].output_base64sha256
  role             = aws_iam_role.role.arn
  timeout          = each.value.timeout

  environment {
    variables = try(each.value.environment, {})
  }

  depends_on = [
    aws_dynamodb_table.table
  ]
}

resource "aws_iam_role_policy_attachment" "execution_role" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  role       = aws_iam_role.role.name
}

# Inline policy granting the Lambda role permission to write to the DynamoDB table and publish to SNS
resource "aws_iam_role_policy" "lambda_permissions" {
  name = "lambda-greetings-permissions"
  role = aws_iam_role.role.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["dynamodb:PutItem"],
        Resource = [aws_dynamodb_table.table.arn]
      },
      {
        Effect   = "Allow",
        Action   = ["sns:Publish"],
        Resource = [var.sns_topic_arn]
      },
      {
        Effect   = "Allow",
        Action   = ["ecs:RunTask"],
        Resource = [var.ecs_task_definition_arn]
      },
      {
        Effect   = "Allow",
        Action   = ["ecs:DescribeTasks"],
        Resource = ["${replace(var.ecs_cluster_arn, ":cluster/", ":task/")}/*"]
      },
      {
        # Allow the Lambda to pass an IAM role to ECS when starting tasks.
        # Scoped to var.ecs_task_role_arn if provided, otherwise falls back to wildcard.
        Effect   = "Allow",
        Action   = ["iam:PassRole"],
        Resource = var.ecs_task_role_arn != "" ? [var.ecs_task_role_arn] : ["*"]
      }
    ]
  })
}
