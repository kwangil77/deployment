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

resource "aws_elb" "internal_elb" {
  name = "${var.environment}-${var.service}-elb"

  subnets = data.aws_subnets.internal.ids
  security_groups = concat(var.security_groups, data.aws_security_groups.selected.ids)
  internal = true

  dynamic "listener" {
    for_each = var.listener
    content {
      instance_port = listener.value.instance_port
      instance_protocol = listener.value.instance_protocol
      lb_port = listener.value.lb_port
      lb_protocol = listener.value.lb_protocol
      ssl_certificate_id = lookup(listener.value, "ssl_certificate_id", null)
    }
  }
  health_check {
    healthy_threshold = lookup(var.health_check, "healthy_threshold")
    unhealthy_threshold = lookup(var.health_check, "unhealthy_threshold")
    target = lookup(var.health_check, "target")
    interval = lookup(var.health_check, "interval")
    timeout = lookup(var.health_check, "timeout")
  }
  tags = {
    Name = var.name
    Team = var.team
    Server = var.server
    Service = var.service
    Security_level = var.security_level
    Environment = var.environment
    Terraform = "true"
  }
}

resource "aws_elb_attachment" "attached" {
  count = length(var.instances)

  elb = aws_elb.internal_elb.id
  instance = var.instances[count.index]
}

output "this_elb_dns_name" {
  value = aws_elb.internal_elb.dns_name
}

output "this_elb_id" {
  value = aws_elb.internal_elb.id
}