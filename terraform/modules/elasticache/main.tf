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

data "aws_security_groups" "selected" {
  tags = {
    Environment = var.environment
    Part = var.part == "ezee" ? var.team : var.part
    Classifier = "team"
  }
}

resource "aws_elasticache_parameter_group" "default" {
  name = var.parameter_group
  family = var.family
}

resource "aws_elasticache_cluster" "default" {
  cluster_id = var.cluster_id
  engine = var.engine
  node_type = var.node_type
  num_cache_nodes = var.num_cache_nodes
  parameter_group_name = aws_elasticache_parameter_group.default.id
  engine_version = var.engine_version
  port = var.port
  subnet_group_name = "${var.environment}-cache-subnetgroup"
  security_group_ids = data.aws_security_groups.selected.ids

  tags = {
    Team = var.team
    Server = var.server
    Service = var.service
    Security_level = var.security_level
    Environment = var.environment
    Terraform = "true"
  }
}