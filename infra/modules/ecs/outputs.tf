output "ecs_cluster" {
  description = "ECS cluster"
  value       = aws_ecs_cluster.cluster
}

output "ecs_task_definition" {
  description = "ECS task definition"
  value       = aws_ecs_task_definition.task.arn
}

output "ecs_security_groups" {
  description = "ECS security groups"
  value       = join(",", [aws_security_group.secgrp.id])
}

output "ecs_task_role_arn" {
  description = "ECS task role arn"
  value       = aws_iam_role.task_role.arn
}

output "ecs_subnets" {
  description = "ECS subnets"
  value       = join(",", data.aws_subnets.subnets.ids)
}
