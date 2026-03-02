locals {
  payload = {
    email  = data.aws_ssm_parameter.candidate_email.value
    repo   = data.aws_ssm_parameter.candidate_repo.value
    source = "ECS"
    region = var.region
  }

  ecs_command = [
    "sns",
    "publish",
    "--topic-arn", var.sns_topic_arn,
    "--message", jsonencode(local.payload)
  ]

  raw_container_definitions = jsonencode([{
    name      = "aws-cli"
    image     = "amazon/aws-cli:2.34.0"
    cpu       = 256
    memory    = 512
    essential = true
    command   = local.ecs_command
  }])

  container_defn_object = jsondecode(local.raw_container_definitions)

  task_container_definitions = jsonencode([
    for definition in local.container_defn_object : merge(
      {
        for key, value in definition : key => value
      },
      try(lookup(definition, "logConfiguration", null) == null ? {
        logConfiguration = {
          logDriver = "awslogs"

          options = {
            awslogs-region        = var.region
            awslogs-stream-prefix = definition.name
            awslogs-group         = aws_cloudwatch_log_group.log.name
          }
        }
      } : {}, {})
    )
  ])
}
