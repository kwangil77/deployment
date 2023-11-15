variable "name" {}
variable "team" {}
variable "server" {}
variable "service" {}
variable "security_level" {}
variable "environment" {}
variable "profile" {}
variable "instances" {
  type = list
  default = []
}