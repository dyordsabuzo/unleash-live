module "ecs" {
  source        = "../modules/ecs"
  cluster       = { name = "unleash" }
  region        = var.region
  sns_topic_arn = var.sns_topic_arn
  task_family   = "ecs-dispatcher"
}

module "functions" {
  source                  = "../modules/lambda"
  dynamodb_table_name     = var.dynamodb_table_name
  sns_topic_arn           = var.sns_topic_arn
  ecs_task_definition_arn = module.ecs.ecs_task_definition
  ecs_cluster_arn         = module.ecs.ecs_cluster.arn
  ecs_task_role_arn       = module.ecs.ecs_task_role_arn

  function_config = [
    {
      name        = "greet"
      description = "Lambda function for greet API endpoint"
      handler     = "greet.handler"
      runtime     = "python3.12"
      filename    = "greet.py"
      timeout     = 10
      environment = {
        SNS_TOPIC_ARN       = var.sns_topic_arn
        DYNAMODB_TABLE_NAME = var.dynamodb_table_name
        LOGLEVEL            = "INFO"
      }
    },
    {
      name        = "dispatch"
      description = "Lambda function for dispatch API endpoint"
      handler     = "dispatch.handler"
      runtime     = "python3.12"
      filename    = "dispatch.py"
      timeout     = 60
      environment = {
        ECS_CLUSTER               = module.ecs.ecs_cluster.id
        ECS_TASK_DEFINITION       = module.ecs.ecs_task_definition
        ECS_SUBNETS               = module.ecs.ecs_subnets
        ECS_SECURITY_GROUPS       = module.ecs.ecs_security_groups
        ECS_WAIT_TIMEOUT_SECONDS  = "300"
        ECS_POLL_INTERVAL_SECONDS = "5"
        LOGLEVEL                  = "INFO"
      }
    }
  ]

  providers = {
    aws         = aws
    aws.cognito = aws.cognito
  }
}

module "api" {
  source                 = "../modules/apigw"
  cognito_user_pool_name = var.cognito_user_pool_name
  lambda_invoke_arns     = module.functions.lambda_invoke_arns

  endpoint_configs = [
    {
      path_part = "greet"
      methods   = ["GET"]
    },
    {
      path_part = "dispatch"
      methods   = ["POST"]
    }
  ]

  providers = {
    aws         = aws
    aws.cognito = aws.cognito
  }
}
