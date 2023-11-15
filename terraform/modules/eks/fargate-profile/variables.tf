variable "cluster_name" {}
variable "fargate_profile_name" {}
variable "namespace" {}
variable "team" {}
variable "server" {}
variable "service" {}
variable "security_level" {}
variable "environment" {}
variable "profile" {}
variable "part" {}
variable "labels" {
  default = {}
}
variable "tags" {
  default = {}
}
variable "role_arn" {}