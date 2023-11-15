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

resource "aws_eks_cluster" "default" {
  name = var.name
  role_arn = var.role_arn
  version = var.kubernetes_version
  
  vpc_config {
    endpoint_private_access = true
    endpoint_public_access = false
    security_group_ids = data.aws_security_groups.selected.ids
    subnet_ids = data.aws_subnets.private.ids
  }
  tags = merge(try(jsondecode(var.tags), var.tags), {
    Team = var.team
    Server = var.server
    Service = var.service
    Security_level = var.security_level
    Environment = var.environment
    Terraform = "true"
  })
}