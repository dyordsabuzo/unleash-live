resource "aws_ecs_cluster" "cluster" {
  name = var.cluster.name

  dynamic "setting" {
    for_each = try(coalesce(var.cluster.enable_container_insights, false), false) ? [1] : []
    content {
      name  = "containerInsights"
      value = "enabled"
    }
  }
}

resource "aws_iam_role" "task_role" {
  name               = "ecs-task-${var.task_family}"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_policy.json
}

resource "aws_iam_role_policy" "task_policy" {
  name   = "ecs-task-permissions-${var.task_family}"
  role   = aws_iam_role.task_role.id
  policy = data.aws_iam_policy_document.task_execution_permissions.json
}

resource "aws_iam_role_policy_attachment" "task_execution_policy" {
  role       = aws_iam_role.task_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "task" {
  family                   = var.task_family
  network_mode             = var.network_mode
  requires_compatibilities = [var.launch_type.type]
  execution_role_arn       = aws_iam_role.task_role.arn
  task_role_arn            = aws_iam_role.task_role.arn
  container_definitions    = local.task_container_definitions
  cpu                      = var.launch_type.cpu
  memory                   = var.launch_type.memory
}

resource "aws_cloudwatch_log_group" "log" {
  name              = "/ecs/${var.cluster.name}/${var.task_family}"
  retention_in_days = 14
}

# firewall setup and default vpc usage
resource "aws_security_group" "secgrp" {
  name        = "${var.task_family}-ecs-secgrp"
  description = "${var.task_family} ecs security group"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "${var.task_family}-ecs-secgrp"
  }
}

resource "aws_vpc_security_group_egress_rule" "all_traffic_ipv4" {
  description       = "Allow outgoing traffic to ipv4 internet"
  security_group_id = aws_security_group.secgrp.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "all_traffic_ipv6" {
  description       = "Allow outgoing traffic to ipv6 internet"
  security_group_id = aws_security_group.secgrp.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1"
}
