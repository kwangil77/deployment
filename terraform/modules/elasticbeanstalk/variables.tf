variable "name" {}
variable "lb_type" {
  default = "application"
}
variable "instance_type" {}
# variable "min_size" {}
variable "max_size" {
  default = 1
}
variable "al_version" {
  default = "2"
}
variable "stack_name" {}
variable "version_label" {
  default = "Sample Application"
}
variable "setting" {
  type = list
  default = []
}
variable "visibility" {
  default = "internal"
}
variable "team" {}
variable "server" {}
variable "service" {}
variable "security_level" {}
variable "environment" {}
variable "profile" {}
variable "part" {}
# variable "health_check_path" {
#   default = "/"
# }
variable "application" {}
variable "cname" {}
variable "tags" {
  default = {}
}
variable "role_arn" {}
variable "processor" {
  default = "x86_64"
}