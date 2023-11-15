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

resource "aws_docdb_cluster_parameter_group" "default" {
  name = var.parameter_group
  family = var.family

  dynamic "parameter" {
    for_each = var.parameter
    content {
      name = parameter.value.name
      value = parameter.value.value
    }
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

resource "aws_docdb_cluster" "default" {
  cluster_identifier = var.cluster_identifier
  engine = var.engine
  master_username = var.master_username
  master_password = var.master_password
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.default.id
  engine_version = var.engine_version
  port = var.port
  db_subnet_group_name = "${var.environment}-db-subnetgroup"
  vpc_security_group_ids = data.aws_security_groups.selected.ids

  tags = merge(try(jsondecode(var.tags), var.tags), {
    Team = var.team
    Server = var.server
    Service = var.service
    Security_level = var.security_level
    Environment = var.environment
    Terraform = "true"
  })
}

resource "aws_docdb_cluster_instance" "default" {
  count = var.instance_count
  identifier = "${var.cluster_identifier}-${count.index}"
  cluster_identifier = "${aws_docdb_cluster.default.id}"
  instance_class = var.instance_class

  tags = merge(try(jsondecode(var.tags), var.tags), {
    Team = var.team
    Server = var.server
    Service = var.service
    Security_level = var.security_level
    Environment = var.environment
    Terraform = "true"
  })
}
