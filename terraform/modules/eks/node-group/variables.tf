variable "cluster_name" {}
variable "node_group_name" {}
variable "ami" {
  default = "AL2_x86_64"
}
variable "capacity_type" {
  default = "ON_DEMAND"
}
variable "instance_types" {
  type = list
  default = []
}
variable "min_size" {}
variable "max_size" {}
variable "instance_count" {}
variable "volume_size" {
  default = "20"
}
variable "team" {}
variable "server" {}
variable "service" {}
variable "security_level" {}
variable "environment" {}
variable "profile" {}
variable "part" {}
variable "tags" {
  default = {}
}
variable "role_arn" {}