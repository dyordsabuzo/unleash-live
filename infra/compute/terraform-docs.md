## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.28.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_api"></a> [api](#module\_api) | ../modules/apigw | n/a |
| <a name="module_ecs"></a> [ecs](#module\_ecs) | ../modules/ecs | n/a |
| <a name="module_functions"></a> [functions](#module\_functions) | ../modules/lambda | n/a |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_cognito_user_pool_arn"></a> [cognito\_user\_pool\_arn](#input\_cognito\_user\_pool\_arn) | The ARN of the Cognito User Pool | `string` | n/a | yes |
| <a name="input_dynamodb_table_name"></a> [dynamodb\_table\_name](#input\_dynamodb\_table\_name) | The name of the DynamoDB table | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name for the infrastructure stack | `string` | `"prod"` | no |
| <a name="input_region"></a> [region](#input\_region) | The AWS region where the resources will be deployed. | `string` | n/a | yes |
| <a name="input_sns_topic_arn"></a> [sns\_topic\_arn](#input\_sns\_topic\_arn) | The ARN of the SNS Topic | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_apigw_invoke_url"></a> [apigw\_invoke\_url](#output\_apigw\_invoke\_url) | API gateway invoke url |
