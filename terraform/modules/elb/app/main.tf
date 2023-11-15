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

module "internal_elb" {
  source = "./.."

  name = var.name

  listener = [
    {
      instance_port = 80
      instance_protocol = "HTTP"
      lb_port = 80
      lb_protocol = "HTTP"
    },
    {
      instance_port = 80
      instance_protocol = "HTTP"
      lb_port = 443
      lb_protocol = "HTTPS"
      ssl_certificate_id = local.certificate_arn[var.profile]
    }
  ]
  health_check = {
    target = "HTTP:80${var.health_check_path}"
    interval = 30
    healthy_threshold = 3
    unhealthy_threshold = 3
    timeout = 10
  }
  instances = var.instances

  Team = var.team
  server = var.server
  service = var.service
  security_level = var.security_level
  environment = var.environment
  profile = var.profile
}

output "this_elb_dns_name" {
  value = module.internal_elb.this_elb_dns_name
}

output "this_elb_id" {
  value = module.internal_elb.this_elb_id
}