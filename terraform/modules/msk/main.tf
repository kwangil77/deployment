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

resource "aws_msk_configuration" "default" {
  kafka_versions = [var.kafka_version]
  name = var.cluster_name

  server_properties = <<PROPERTIES
auto.create.topics.enable=false
default.replication.factor=3
min.insync.replicas=2
num.io.threads=8
num.network.threads=5
num.partitions=1
num.replica.fetchers=2
replica.lag.time.max.ms=30000
socket.receive.buffer.bytes=102400
socket.request.max.bytes=104857600
socket.send.buffer.bytes=102400
unclean.leader.election.enable=true
zookeeper.session.timeout.ms=18000
PROPERTIES
}

resource "aws_msk_cluster" "default" {
  cluster_name = var.cluster_name
  kafka_version = var.kafka_version
  number_of_broker_nodes = var.number_of_broker_nodes

  broker_node_group_info {
    instance_type = var.broker_instance_type
    ebs_volume_size = var.ebs_volume_size
    client_subnets = slice(tolist(data.aws_subnets.private.ids), 0, var.number_of_broker_nodes)
    security_groups = data.aws_security_groups.selected.ids
  }
  configuration_info {
    arn = aws_msk_configuration.default.arn
    revision = aws_msk_configuration.default.latest_revision
  }
  encryption_info {
    encryption_in_transit {
      client_broker = "TLS_PLAINTEXT"
    }
  }
  open_monitoring {
    prometheus {
      jmx_exporter {
        enabled_in_broker = true
      }
      node_exporter {
        enabled_in_broker = true
      }
    }
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