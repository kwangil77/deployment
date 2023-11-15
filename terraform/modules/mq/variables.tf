variable "broker_name" {}
variable "engine_type" {
  default = "RabbitMQ"
}
variable "engine_version" {}
variable "host_instance_type" {}
variable "deployment_mode" {
  default = "SINGLE_INSTANCE"
}
variable "username" {}
variable "password" {}
variable "team" {}
variable "server" {}
variable "service" {}
variable "security_level" {}
variable "environment" {}
variable "profile" {}
variable "part" {}