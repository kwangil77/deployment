variable "cluster_identifier" {}
variable "engine" {}
variable "instance_class" {}
variable "instance_count" {}
variable "master_username" {}
variable "master_password" {}
variable "engine_version" {}
variable "port" {}
variable "parameter_group" {}
variable "parameter" {
  type = list
  default = []
}
variable "family" {}
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