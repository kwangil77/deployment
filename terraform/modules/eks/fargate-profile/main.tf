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

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  filter {
    name = "tag:kubernetes.io/cluster/${var.cluster_name}"
    values = ["shared"]
  }
  tags = {
    Environment = var.environment
    Part = var.part
    Classifier = "team"
  }
}

resource "aws_eks_fargate_profile" "default" {
  cluster_name = var.cluster_name
  fargate_profile_name = var.fargate_profile_name
  pod_execution_role_arn = var.role_arn
  subnet_ids = data.aws_subnets.private.ids

  selector {
    namespace = var.namespace
    labels = try(jsondecode(var.labels), var.labels)
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