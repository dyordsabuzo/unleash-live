## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_archive"></a> [archive](#provider\_archive) | n/a |
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_dynamodb_table.table](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |
| [aws_iam_role.role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.lambda_permissions](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy_attachment.execution_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_lambda_function.function](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_function) | resource |
| [archive_file.archive](https://registry.terraform.io/providers/hashicorp/archive/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_dynamodb_table_name"></a> [dynamodb\_table\_name](#input\_dynamodb\_table\_name) | DynamoDB table name | `string` | n/a | yes |
| <a name="input_ecs_cluster_arn"></a> [ecs\_cluster\_arn](#input\_ecs\_cluster\_arn) | Dispatcher ecs cluster arn | `string` | n/a | yes |
| <a name="input_ecs_task_definition_arn"></a> [ecs\_task\_definition\_arn](#input\_ecs\_task\_definition\_arn) | Dispatcher ecs task definition arn | `string` | n/a | yes |
| <a name="input_ecs_task_role_arn"></a> [ecs\_task\_role\_arn](#input\_ecs\_task\_role\_arn) | ECS task role arn | `string` | n/a | yes |
| <a name="input_function_config"></a> [function\_config](#input\_function\_config) | Lambda function configuration | <pre>list(object({<br/>    name        = string<br/>    description = string<br/>    filename    = string<br/>    handler     = string<br/>    runtime     = string<br/>    timeout     = number<br/>    environment = optional(map(string))<br/>  }))</pre> | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The AWS region where the resources will be deployed. | `string` | `"us-east-1"` | no |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | The ARN of the SNS topic | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_dynamodb_table_name"></a> [dynamodb\_table\_name](#output\_dynamodb\_table\_name) | DynamoDB table name used for greeting logs |
| <a name="output_lambda_invoke_arns"></a> [lambda\_invoke\_arns](#output\_lambda\_invoke\_arns) | Lambda function invoke arns |
