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
  service = "${var.service}${length(var.type) > 0 ? "-${var.type}" : ""}"
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
    values = data.aws_ec2_instance_type_offerings.selected.locations
  }
  tags = {
    Environment = var.environment
    Part = var.part
    Classifier = "team"
  }
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

data "template_file" "user_data" {
  template = file("${path.module}/../../templates/user_data.tpl")

  vars = {
    team = "se"
    os = var.os
  }
}

resource "aws_launch_configuration" "lc" {
  name = "${var.environment}-${local.service}-lc"
  # image_id = coalesce(var.ami, data.aws_ami.selected.image_id)
  image_id = var.ami
  instance_type = var.instance_type
  security_groups = data.aws_security_groups.selected.ids

  dynamic "root_block_device" {
    for_each = var.root_block_device
    content {
      delete_on_termination = lookup(root_block_device.value, "delete_on_termination", null)
      iops = lookup(root_block_device.value, "iops", null)
      volume_size = lookup(root_block_device.value, "volume_size", null)
      volume_type = lookup(root_block_device.value, "volume_type", null)
    }
  }
  dynamic "ebs_block_device" {
    for_each = var.ebs_block_device
    content {
      delete_on_termination = lookup(ebs_block_device.value, "delete_on_termination", null)
      device_name = ebs_block_device.value.device_name
      encrypted = lookup(ebs_block_device.value, "encrypted", null)
      iops = lookup(ebs_block_device.value, "iops", null)
      no_device = lookup(ebs_block_device.value, "no_device", null)
      snapshot_id = lookup(ebs_block_device.value, "snapshot_id", null)
      volume_size = lookup(ebs_block_device.value, "volume_size", null)
      volume_type = lookup(ebs_block_device.value, "volume_type", null)
    }
  }
  # user_data = data.template_file.user_data.rendered
  iam_instance_profile = split("/", var.role_arn)[1]
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "asg" {
  name = "${var.environment}-${local.service}-asg"
  launch_configuration = aws_launch_configuration.lc.name
  vpc_zone_identifier = data.aws_subnets.private.ids
  health_check_type = "EC2"
  termination_policies = ["OldestInstance"]
  min_size = var.min_size
  max_size = var.max_size
  desired_capacity = var.instance_count

  initial_lifecycle_hook {
    name = "NewHost"
    default_result = "CONTINUE"
    heartbeat_timeout = 2000
    lifecycle_transition = "autoscaling:EC2_INSTANCE_LAUNCHING"
    notification_target_arn = var.sqs_arn[var.profile]
    role_arn = var.role_arn
  }
  initial_lifecycle_hook {
    name = "RemoveHost"
    default_result = "CONTINUE"
    heartbeat_timeout = 2000
    lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"
    notification_target_arn = var.sqs_arn[var.profile]
    role_arn = var.role_arn
  }
  load_balancers = compact(concat(list(var.load_balancer), var.load_balancers))
  target_group_arns = compact(concat(list(var.target_group_arn), var.target_group_arns))

  tags = [
    {
      key = "Team"
      value = var.team
      propagate_at_launch = true
    },
    {
      key = "Server"
      value = var.server
      propagate_at_launch = true
    },
    {
      key = "Service"
      value = var.service
      propagate_at_launch = true
    },
    {
      key = "Security_level"
      value = var.security_level
      propagate_at_launch = true
    },
    {
      key = "Environment"
      value = var.environment
      propagate_at_launch = true
    },
    {
      key = "Role"
      value = var.service
      propagate_at_launch = true
    },
    {
      key = "Name"
      value = var.name
      propagate_at_launch = true
    }
  ]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_policy" "down_policy" {
  name = "${var.environment}-${local.service}-asg-scale-down-policy"
  scaling_adjustment = -1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

resource "aws_autoscaling_policy" "up_policy" {
  name = "${var.environment}-${local.service}-asg-scale-up-policy"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

resource "aws_cloudwatch_metric_alarm" "down_alarm" {
  alarm_name = "${var.environment}-${local.service}-asg-scale-alarm-low"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "3"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "300"
  statistic = "Average"
  threshold = "5.0"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
  alarm_description = "This will alarm when cpu usage average is lower than 5% for 15 minutes"
  alarm_actions = [aws_autoscaling_policy.down_policy.arn]
}

resource "aws_cloudwatch_metric_alarm" "up_alarm" {
  alarm_name = "${var.environment}-${local.service}-asg-scale-alarm-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "3"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "300"
  statistic = "Average"
  threshold = "90.0"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
  alarm_description = "This will alarm when cpu usage average is higher than 90% for 15 minutes"
  alarm_actions = [aws_autoscaling_policy.up_policy.arn]
}

output "this_autoscaling_group_name" {
  value = aws_autoscaling_group.asg.name
}

output "this_launch_configuration_name" {
  value = aws_launch_configuration.lc.name
}