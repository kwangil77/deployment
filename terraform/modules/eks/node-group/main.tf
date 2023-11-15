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

data "aws_ec2_instance_type_offerings" "selected" {
  filter {
    name = "instance-type"
    values = var.instance_types
  }
  location_type = "availability-zone"
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
  filter {
    name = "tag:Az"
    values = data.aws_ec2_instance_type_offerings.selected.locations
  }
  tags = {
    Environment = var.environment
    Part = var.part
    Classifier = "team"
  }
}

data "aws_launch_template" "selected" {
  name = "${var.profile}-${var.part == "tc" ? "ce" : var.part}-LaunchTemplate"
  # tags = {
  #   Environment = var.environment
  #   Part = var.part == "tc" ? "ce" : var.part
  #   Classifier = "team"
  # }
}

resource "aws_eks_node_group" "default" {
  cluster_name = var.cluster_name
  node_group_name = var.node_group_name
  node_role_arn = var.role_arn
  subnet_ids = data.aws_subnets.private.ids

  ami_type = var.ami
  capacity_type = var.capacity_type
  # disk_size = var.volume_size
  instance_types = var.instance_types
  
  scaling_config {
    desired_size = var.instance_count
    max_size = var.max_size
    min_size = var.min_size
  }
  launch_template {
    id = data.aws_launch_template.selected.id
    version = data.aws_launch_template.selected.latest_version
  }
  labels = {
    team = var.team
    part = var.part
    role = "worker"
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