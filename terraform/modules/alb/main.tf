terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  backend "pg" {}
}

locals {
  certificate_arn = {
    "example-dev" = "arn:aws:acm:ap-northeast-2:..."
  }
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

data "aws_security_groups" "selected" {
  tags = {
    Environment = var.environment
    Classifier = "internal_lb"
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

resource "aws_lb" "internal_alb" {
  load_balancer_type = "application"
  name = "${var.environment}-${var.service}-alb"
  security_groups = data.aws_security_groups.selected.ids
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
  name = "${var.environment}-${var.service}-tg"
  vpc_id = data.aws_vpc.selected.id
  port = 80
  protocol = "HTTP"
  target_type = "instance"

  health_check {
    interval = 10
    path = var.health_check_path
    timeout = 5
    matcher = "200-299"
  }
  stickiness {
    type = "lb_cookie"
  }
  tags = {
    Team = var.team
    Server = var.server
    Service = var.service
    Security_level = var.security_level
    Environment = var.environment
    Terraform = "true"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener" "internal_https" {
  load_balancer_arn = aws_lb.internal_alb.arn
  port = 443
  protocol = "HTTPS"
  certificate_arn = local.certificate_arn[var.profile]
  ssl_policy = "ELBSecurityPolicy-2016-08"

  default_action {
    target_group_arn = aws_lb_target_group.internal_tg.arn
    type = "forward"
  }
}
resource "aws_lb_listener" "internal_http_tcp" {
  load_balancer_arn = aws_lb.internal_alb.arn
  port = 80
  protocol = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.internal_tg.arn
    type = "forward"
  }
}

resource "aws_lb_target_group_attachment" "attached" {
  count = length(var.instances)

  target_group_arn = aws_lb_target_group.internal_tg.arn
  target_id = var.instances[count.index]
  port = 80
}

output "lb_dns_name" {
  value = aws_lb.internal_alb.dns_name
}

output "target_group_arns" {
  value = aws_lb_target_group.internal_tg.arn
}