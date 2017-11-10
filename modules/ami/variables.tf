variable "region" {
  type = "string"
  description = "The region for this AMI."
}

variable "user" {
  type = "string"
  description = "The OS user that is used to login to the AMI."

  default = "core"
}

variable "operating_system" {
  type = "string"
  description = "The operating system to use."
}
