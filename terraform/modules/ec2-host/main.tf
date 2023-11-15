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

data "aws_ec2_instance_type_offerings" "selected" {
  filter {
    name = "instance-type"
    values = [var.instance_type]
  }
  location_type = "availability-zone"
}

resource "aws_ec2_host" "ec2_host" {
  instance_type = var.instance_type
  availability_zone = data.aws_ec2_instance_type_offerings.selected.locations[0]

  tags = {
    Name = var.name
    Team = var.team
    Server = var.server
    Service = var.service
    Security_level = var.security_level
    Environment = var.environment
    Terraform = "true"
  }
}