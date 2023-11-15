variable "name" {}
variable "security_groups" {
  type = list
  default = []
}
variable "listener" {
  type = list
}
variable "health_check" {
  type = map
}
variable "instances" {
  type = list
  default = []
}
variable "team" {}
variable "server" {}
variable "service" {}
variable "security_level" {}
variable "environment" {}
variable "profile" {}