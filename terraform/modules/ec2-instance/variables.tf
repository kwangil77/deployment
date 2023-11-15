variable "name" {}
variable "ami" {
  default = ""
}
variable "instance_type" {}
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
variable "role_arn" {}
variable "processor" {
  default = "x86_64"
}
variable "eb_name" {
  default = ""
}
variable "host_id" {
  default = ""
}