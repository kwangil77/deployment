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

data "aws_ec2_instance_type_offerings" "selected" {
  filter {
    name = "instance-type"
    values = [var.instance_type]
  }
  location_type = "availability-zone"
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  filter {
    name = "tag:Az"
    values = var.host_id == "" ? data.aws_ec2_instance_type_offerings.selected.locations : [data.aws_ec2_instance_type_offerings.selected.locations[0]]
  }
  tags = {
    Environment = var.environment
    Part = contains(["traveluniv-dev", "traveluniv-prod", "traveluniv-privacy-prod", "fnb-dev", "fnb-prod", "fnb-privacy-prod"], var.profile) ? "tc" : var.part
    Classifier = "team"
  }
}

data "aws_ami" "selected" {
  most_recent = true
  owners = ["122797595191"]

  filter {
    name = "tag:Service"
    values = ["AMI"]
  }
  filter {
    name = "tag:Version"
    values = ["stable"]
  }
  filter {
    name = "tag:Platform"
    values = ["amzn2-${var.processor}"]
  }
}

data "template_file" "user_data" {
  template = file("${path.module}/../../templates/user_data.tpl")

  vars = {
    instance_type = var.instance_type
  }
}

resource "aws_instance" "ec2_instance" {
  count = var.instance_count

  ami = coalesce(var.ami, data.aws_ami.selected.image_id)
  # ami = var.ami
  instance_type = var.instance_type
  iam_instance_profile = split("/", var.role_arn)[1]
  vpc_security_group_ids = data.aws_security_groups.selected.ids
  subnet_id = element(tolist(data.aws_subnets.private.ids), count.index)

  dynamic "root_block_device" {
    for_each = var.root_block_device
    content {
      volume_size = var.host_id == "" ? lookup(root_block_device.value, "volume_size", null) : "100"
      volume_type = lookup(root_block_device.value, "volume_type", null)
    }
  }
  dynamic "ebs_block_device" {
    for_each = var.ebs_block_device
    content {
      device_name = ebs_block_device.value.device_name
      volume_size = lookup(ebs_block_device.value, "volume_size", null)
      volume_type = lookup(ebs_block_device.value, "volume_type", null)
    }
  }
  tenancy = var.host_id == "" ? "default" : "host"
  host_id = var.host_id == "" ? null : var.host_id
  user_data = var.host_id == "" ? null : data.template_file.user_data.rendered

  tags = {
    Name = var.name
    Team = var.team
    Server = var.server
    Service = var.service
    Security_level = var.security_level
    Environment = var.environment
    Terraform = "true"
    "elasticbeanstalk:environment-name" = var.eb_name
  }
}

output "id" {
  value = aws_instance.ec2_instance.*.id
}

output "subnet_id" {
  value = aws_instance.ec2_instance.*.subnet_id
}

output "security_groups" {
  value = aws_instance.ec2_instance.*.security_groups
}