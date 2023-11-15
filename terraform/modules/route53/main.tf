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
  internal_zone_id = {
    "dev" = ""
  }
  local_zone_id = {
    "dev" = ""
  }
}

provider "aws" {
  region = "ap-northeast-2"
  profile = var.profile
}

resource "aws_route53_record" "internal" {
  zone_id = local.internal_zone_id[var.environment]
  name = var.name
  type = "CNAME"
  ttl = "300"
  records = [var.lb_dns_name]
}

resource "aws_route53_record" "default" {
  zone_id = local.local_zone_id[var.environment]
  name = var.name
  type = "CNAME"
  ttl = "300"
  records = [aws_route53_record.internal.fqdn]
}

output "this_internal_fqdn" {
  value = aws_route53_record.internal.fqdn
}

output "this_local_fqdn" {
  value = aws_route53_record.default.fqdn
}