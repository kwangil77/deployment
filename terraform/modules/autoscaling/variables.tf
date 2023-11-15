variable "name" {}
variable "ami" {}
variable "instance_type" {}
variable "min_size" {}
variable "max_size" {}
variable "instance_count" {}
variable "root_block_device" {
  type = list
  default = [
    {
      volume_type = "gp3"
      volume_size = "8"
    }
  ]
}
variable "ebs_block_device" {
  type = list
  default = []
}
variable "team" {}
variable "server" {}
variable "service" {}
variable "security_level" {}
variable "environment" {}
variable "profile" {}
variable "part" {}
variable "type" {
  default = ""
}
variable "load_balancer" {
  default = ""
}
variable "load_balancers" {
  type = list
  default = []
}
variable "target_group_arn" {
  default = ""
}
variable "target_group_arns" {
  type = list
  default = []
}
variable "sqs_arn" {
  type = map
  default = {
    "example-dev" = "arn:aws:sqs:ap-northeast-2:..."
  }
}
variable "os" {
  default = ""
}
variable "role_arn" {}