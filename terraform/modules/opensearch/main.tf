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
  filter {
    name = "tag:Az"
    values = ["*-2a", "*-2c"]
  }
  tags = {
    Environment = var.environment
    Part = var.part
    Classifier = "team"
  }
}

resource "aws_opensearch_domain" "default" {
  domain_name = var.domain_name
  engine_version = var.engine_version

  ebs_options {
    ebs_enabled = true
    volume_type = "gp2"
    volume_size = var.ebs_volume_size
  }
  cluster_config {
    instance_type = var.cluster_instance_type
    instance_count = var.cluster_instance_count
    dedicated_master_enabled = var.dedicated_master_count > 0
    dedicated_master_type = var.cluster_instance_type
    dedicated_master_count = var.dedicated_master_count
  }
  vpc_options {
    subnet_ids = slice(tolist(data.aws_subnets.private.ids), 0, (var.cluster_instance_count > 1 ? 2 : 1))
    security_group_ids = data.aws_security_groups.selected.ids
  }
  snapshot_options {
    automated_snapshot_start_hour = 0
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

resource "aws_opensearch_domain_policy" "default" {
  domain_name = aws_opensearch_domain.default.domain_name

  access_policies = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "es:*",
      "Principal": {
        "AWS": "*"
      },
      "Effect": "Allow",
      "Resource": "${aws_opensearch_domain.default.arn}/*"
    }
  ]
}
EOF
}