terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "pg" {}
}

provider "aws" {
  region = "ap-northeast-2"
  profile = var.profile
}

data "aws_vpc" "selected" {
  tags = {
    Environment = var.environment
  }
}

data "aws_subnets" "internal" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  tags = {
    Environment = var.environment
    Classifier = "internal_lb"
  }
}

resource "aws_lb" "internal_nlb" {
  load_balancer_type = "network"
  name = "${var.environment}-${var.service}-nlb"
  internal = true
  subnets = data.aws_subnets.internal.ids

  tags = {
    Team = var.team
    Server = var.server
    Service = var.service
    Security_level = var.security_level
    Environment = var.environment
    Terraform = "true"
  }
}

resource "aws_lb_target_group" "internal_tg" {
  name = lookup(var.target_groups[count.index], "name")
  vpc_id = data.aws_vpc.selected.id
  port = lookup(var.target_groups[count.index], "backend_port")
  protocol = lookup(var.target_groups[count.index], "backend_protocol")
  deregistration_delay = lookup(var.target_groups[count.index], "deregistration_delay", null)
  target_type = lookup(var.target_groups[count.index], "target_type")
  slow_start = lookup(var.target_groups[count.index], "slow_start", null)

  dynamic "health_check" {
    for_each = [lookup(var.target_groups[count.index], "health_check", {})]
    content {
      interval = lookup(health_check.value, "interval", null)
      port = lookup(health_check.value, "port", null)
      healthy_threshold = lookup(health_check.value, "healthy_threshold", null)
      unhealthy_threshold = lookup(health_check.value, "unhealthy_threshold", null)
      protocol = "TCP"
    }
  }
  tags = {
    Team = var.team
    Server = var.server
    Service = var.service
    Security_level = var.security_level
    Environment = var.environment
    Terraform = "true"
  }
  count = length(var.target_groups)

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "internal_tls" {
  load_balancer_arn = aws_lb.internal_nlb.arn
  port = lookup(var.tls_listeners[count.index], "port")
  protocol = "TLS"
  certificate_arn = lookup(var.tls_listeners[count.index], "certificate_arn")
  ssl_policy = lookup(var.tls_listeners[count.index], "ssl_policy")
  count = length(var.tls_listeners)

  default_action {
    target_group_arn = aws_lb_target_group.internal_tg.*.arn[lookup(var.tls_listeners[count.index], "target_group_index", 0)]
    type = "forward"
  }
}

resource "aws_lb_listener" "internal_tcp_udp" {
  load_balancer_arn = aws_lb.internal_nlb.arn
  port = lookup(var.tcp_udp_listeners[count.index], "port")
  protocol = lookup(var.tcp_udp_listeners[count.index], "protocol")
  count = length(var.tcp_udp_listeners)

  default_action {
    target_group_arn = aws_lb_target_group.internal_tg.*.arn[lookup(var.tcp_udp_listeners[count.index], "target_group_index", 0)]
    type = "forward"
  }
}

resource "aws_lb_target_group_attachment" "attached" {
  count = length(var.instances)

  target_group_arn = aws_lb_target_group.internal_tg.*.arn[lookup(var.tcp_udp_listeners[count.index], "target_group_index", 0)]
  target_id = var.instances[count.index]
  port = lookup(var.target_groups[count.index], "backend_port")
}

output "lb_dns_name" {
  value = aws_lb.internal_nlb.dns_name
}

output "target_group_arns" {
  value = aws_lb_target_group.internal_tg.*.arn
}