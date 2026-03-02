output "lambda_invoke_arns" {
  description = "Lambda function invoke arns"
  value = { for function in aws_lambda_function.function :
    function.function_name => function.invoke_arn
  }
}

output "dynamodb_table_name" {
  description = "DynamoDB table name used for greeting logs"
  value       = aws_dynamodb_table.table.name
}
