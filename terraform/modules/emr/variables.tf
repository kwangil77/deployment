variable "name" {}
variable "release_label" {}
variable "applications" {
  type = list
  default = []
}
variable "master_instance_type" {}
variable "master_instance_count" {
  default = 1
}
variable "core_instance_type" {}
variable "core_instance_count" {}
variable "team" {}
variable "server" {}
variable "service" {}
variable "security_level" {}
variable "environment" {}
variable "profile" {}
variable "part" {}