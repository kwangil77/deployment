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
  log_uri = {
    "example-dev" = "s3://aws-logs-...-ap-northeast-2/elasticmapreduce/"
  }
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

data "aws_security_groups" "emr" {
  tags = {
    Name = "${var.profile}-emr-sg"
  }
}

resource "aws_emr_cluster" "default" {
  name = var.name
  release_label = var.release_label
  applications = var.applications

  termination_protection = var.master_instance_count == 1
  keep_job_flow_alive_when_no_steps = true

  ec2_attributes {
    subnet_id = tolist(data.aws_subnets.private.ids)[0]
    emr_managed_master_security_group = data.aws_security_groups.emr.ids[0]
    emr_managed_slave_security_group = data.aws_security_groups.emr.ids[0]
    service_access_security_group = data.aws_security_groups.selected.ids[0]
    instance_profile = "EMR_EC2_DefaultRole"
  }
  master_instance_group {
    instance_type = var.master_instance_type
    instance_count = var.master_instance_count
  }
  core_instance_group {
    instance_type = var.core_instance_type
    instance_count = var.core_instance_count
  }
  configurations_json = <<EOF
[
  {
    "Classification": "hbase",
    "Properties": {
      "hbase.emr.storageMode": "s3"
    }
  },
  {
    "Classification": "hbase-site",
    "Properties": {
      "hbase.rootdir": "s3://.../"
    }
  }
]
EOF
  log_uri = local.log_uri[var.profile]
  service_role = "EMR_DefaultRole"
  autoscaling_role = "EMR_AutoScaling_DefaultRole"

  bootstrap_action {
    path = "s3://.../vault.sh"
    name = "vault"
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