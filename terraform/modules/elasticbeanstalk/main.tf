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
    Environment = contains(["hotelnow-prod", "yapen-prod"], var.profile)  ? "prod" : var.environment
  }
}

data "aws_security_groups" "selected" {
  tags = {
    Environment = var.profile == "hotelnow-prod" ? "prod" : var.environment
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
    values = data.aws_ec2_instance_type_offerings.selected.locations
  }
  tags = {
    Environment = var.profile == "hotelnow-prod" ? "prod" : var.environment
    Part = contains(["traveluniv-dev", "traveluniv-prod", "traveluniv-privacy-prod", "fnb-dev", "fnb-prod", "fnb-privacy-prod"], var.profile) ? "tc" : var.part
    Classifier = "team"
  }
}

data "aws_subnets" "internal" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
  filter {
    name = "tag:Az"
    values = data.aws_ec2_instance_type_offerings.selected.locations
  }
  tags = {
    Environment = var.profile == "hotelnow-prod" ? "prod" : var.environment
    Classifier = (var.visibility == "internal") ? "internal_lb" : "external_lb"
  }
}

data "aws_elastic_beanstalk_solution_stack" "solution_stack" {
  most_recent = true
  name_regex = "^64bit Amazon Linux ${var.al_version == "2" ? "${var.al_version} " : ""}(.*) running ${var.stack_name}(.*)$"
}

# data "aws_ami" "selected" {
#   most_recent = true
#   owners = ["122797595191"]

#   filter {
#     name = "tag:Service"
#     values = ["AMI"]
#   }
#   filter {
#     name = "tag:Version"
#     values = ["stable"]
#   }
# }

resource "aws_elastic_beanstalk_environment" "environment" {
  name = var.name
  application = var.application
  cname_prefix = var.cname
  description = var.name
  tier = "WebServer"
  solution_stack_name = data.aws_elastic_beanstalk_solution_stack.solution_stack.name
  version_label = var.version_label

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name = "ServiceRole"
    value = "aws-elasticbeanstalk-service-role"
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name = "LoadBalancerType"
    value = var.lb_type
  }
  # setting {
  #   namespace = "aws:elasticbeanstalk:environment:process:default"
  #   name = "HealthCheckPath"
  #   value = var.health_check_path
  # }
  # setting {
  #   namespace = "aws:elbv2:listener:443"
  #   name = "SSLPolicy"
  #   value = "ELBSecurityPolicy-2016-08"
  # }
  # setting {
  #   namespace = "aws:elbv2:listener:443"
  #   name = "SSLCertificateArns"
  #   value = local.certificate_arn[var.profile]
  # }
  # setting {
  #   namespace = "aws:elbv2:listener:443"
  #   name = "Protocol"
  #   value = "HTTPS"
  # }
  setting {
    namespace = "aws:elasticbeanstalk:hostmanager"
    name = "LogPublicationControl"
    value = "true"
  }
  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name = "RetentionInDays"
    value = "7"
  }
  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name = "DeleteOnTerminate"
    value = "false"
  }
  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name = "StreamLogs"
    value = "true"
  }
  # setting {
  #   namespace = "aws:autoscaling:launchconfiguration"
  #   name = "ImageId"
  #   value = data.aws_ami.selected.image_id
  # }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "SecurityGroups"
    value = join(",", data.aws_security_groups.selected.ids)
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "IamInstanceProfile"
    value = split("/", var.role_arn)[1]
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "RootVolumeType"
    value = "gp3"
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "RootVolumeSize"
    value = "10"
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "RootVolumeIOPS"
    value = "3000"
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "RootVolumeThroughput"
    value = "125"
  }
  # setting {
  #   namespace = "aws:autoscaling:launchconfiguration"
  #   name = "InstanceType"
  #   value = var.instance_type
  # }
  # setting {
  #   namespace = "aws:autoscaling:asg"
  #   name = "MinSize"
  #   value = var.min_size
  # }
  setting {
    namespace = "aws:autoscaling:asg"
    name = "MaxSize"
    value = var.max_size
  }
  # setting {
  #   namespace = "aws:elasticbeanstalk:command"
  #   name = "BatchSize"
  #   value = "100"
  # }
  # setting {
  #   namespace = "aws:elasticbeanstalk:command"
  #   name = "BatchSizeType"
  #   value = "Percentage" // Percentage, Fixed
  # }
  setting {
    namespace = "aws:elasticbeanstalk:command"
    name = "DeploymentPolicy"
    value = "AllAtOnce" // AllAtOnce, Rolling, RollingWithAdditionalBatch, Immutable
  }
#   setting {
#     namespace = "aws:elasticbeanstalk:healthreporting:system"
#     name = "ConfigDocument"
#     value = <<EOF
# {
#   "CloudWatchMetrics": {
#     "Environment": {
#       "ApplicationLatencyP10": 60,
#       "ApplicationLatencyP50": 60,
#       "ApplicationLatencyP75": 60,
#       "ApplicationLatencyP85": 60,
#       "ApplicationLatencyP90": 60,
#       "ApplicationLatencyP95": 60,
#       "ApplicationLatencyP99": 60,
#       "ApplicationLatencyP99.9": 60,
#       "ApplicationRequests2xx": 60,
#       "ApplicationRequests3xx": 60,
#       "ApplicationRequests4xx": 60,
#       "ApplicationRequests5xx": 60,
#       "ApplicationRequestsTotal": 60,
#       "InstancesDegraded": 60,
#       "InstancesInfo": 60,
#       "InstancesNoData": 60,
#       "InstancesOk": 60,
#       "InstancesPending": 60,
#       "InstancesSevere": 60,
#       "InstancesUnknown": 60,
#       "InstancesWarning": 60
#     },
#     "Instance": {
#       "ApplicationLatencyP10": 60,
#       "ApplicationLatencyP50": 60,
#       "ApplicationLatencyP75": 60,
#       "ApplicationLatencyP85": 60,
#       "ApplicationLatencyP90": 60,
#       "ApplicationLatencyP95": 60,
#       "ApplicationLatencyP99": 60,
#       "ApplicationLatencyP99.9": 60,
#       "ApplicationRequests2xx": 60,
#       "ApplicationRequests3xx": 60,
#       "ApplicationRequests4xx": 60,
#       "ApplicationRequests5xx": 60,
#       "ApplicationRequestsTotal": 60,
#       "CPUIdle": 60,
#       "CPUIowait": 60,
#       "CPUIrq": 60,
#       "CPUNice": 60,
#       "CPUSoftirq": 60,
#       "CPUSystem": 60,
#       "CPUUser": 60,
#       "InstanceHealth": 60,
#       "LoadAverage1min": 60,
#       "LoadAverage5min": 60,
#       "RootFilesystemUtil": 60
#     }
#   },
#   "Version": 1
# }
# EOF
#   }
  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name = "SystemType"
    value = "basic" // enhanced, basic
  }
  setting {
    namespace = "aws:ec2:vpc"
    name = "VPCId"
    value = data.aws_vpc.selected.id
  }
  setting {
    namespace = "aws:ec2:vpc"
    name = "Subnets"
    value = join(",", data.aws_subnets.private.ids)
  }
  setting {
    namespace = "aws:ec2:vpc"
    name = "ELBSubnets"
    value = join(",", data.aws_subnets.internal.ids)
  }
  setting {
    namespace = "aws:ec2:vpc"
    name = "ELBScheme"
    value = var.visibility
  }
  setting {
    namespace = "aws:ec2:vpc"
    name = "AssociatePublicIpAddress"
    value = "false"
  }
  setting {
    namespace = "aws:ec2:instances"
    name = "SupportedArchitectures"
    value = var.processor
  }
  dynamic "setting" {
    for_each = var.setting
    content {
      namespace = setting.value.namespace
      name = setting.value.name
      value = setting.value.value
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
