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
    Part = var.part == "ezee" ? var.team : var.part
    Classifier = "team"
  }
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  tags = {
    Environment = var.environment
    Part = var.part
    Classifier = "team"
  }
}

resource "aws_mq_broker" "default" {
  broker_name = var.broker_name
  engine_type = var.engine_type
  engine_version = var.engine_version
  host_instance_type = var.host_instance_type
  deployment_mode = var.deployment_mode
  security_groups = data.aws_security_groups.selected.ids
  subnet_ids = var.deployment_mode == "SINGLE_INSTANCE" ? slice(tolist(data.aws_subnets.private.ids), 0, 1) : data.aws_subnets.private.ids

  user {
    username = var.username
    password = var.password
  }
  tags = {
    Team = var.team
    Server = var.server
    Service = var.service
    Security_level = var.security_level
    Environment = var.environment
    Terraform = "true"
  }
}