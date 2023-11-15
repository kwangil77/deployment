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

module "internal_nlb" {
  source = "./.."

  name = var.name

  tls_listeners = [
    {
      certificate_arn = local.certificate_arn[var.profile]
      ssl_policy = "ELBSecurityPolicy-2016-08"
      port = 443
    }
  ]
  tcp_udp_listeners = [
    {
      protocol = "TCP"
      port = 80
    }
  ]
  target_groups = [
    {
      name = "${var.environment}-${var.service}-tg"
      backend_protocol = "TCP"
      backend_port = 80
      target_type = "instance"
      health_check = {
        interval = 10
      }
    }
  ]
  instances = var.instances

  team = var.team
  server = var.server
  service = var.service
  security_level = var.security_level
  environment = var.environment
  profile = var.profile
}

output "lb_dns_name" {
  value = module.internal_nlb.lb_dns_name
}

output "target_group_arns" {
  value = module.internal_nlb.target_group_arns
}