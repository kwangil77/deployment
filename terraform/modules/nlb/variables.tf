variable "name" {}
variable "tls_listeners" {
  type = list
  default = []
}
variable "tcp_udp_listeners" {
  type = list
  default = []
}
variable "target_groups" {
  type = list
  default = []
}
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