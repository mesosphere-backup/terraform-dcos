variable "cluster_id" {
  type = "string"
  description = "An identifier for this cluster."
}

variable "number_of_instances" {
  type = "string"
  description = "The number of master instances to spin up."
}

variable "disk_size" {
  type = "string"
  description = "Disk size in GB"

  default = "128"
}

variable "instance_type" {
  type = "string"
  description = "The instance type this instance should be."
}

variable "subnet_id" {
  type = "string"
  description = "The subnet id this instance should belong to"
}

variable "instance_ami" {
  type = "string"
  description = "The AMI to use for this instance."
}

variable "instance_ami_user" {
  type = "string"
  description = "The user to use to log in to this instance."
}

variable "key_name" {
  type = "string"
  description = "The key to use for this instance."
}

variable "security_groups" {
  type = "list"
  description = "A list of security groups that should be added."
}

variable "bootstrap_url" {
  type = "string"
  description = "URL the bootstrap script will be available at."
}

variable "bootstrap_port" {
  type = "string"
  description = "Port the bootstrap script will be available at."
}
