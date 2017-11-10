variable "cluster_id" {
  type = "string"
  description = "An identifier for this cluster."
}

variable "region" {
  type = "string"
  description = "The AWS region to use for this master-region."
}

variable "public_key" {
  type = "string"
  description = "The key to use for this region."
}

variable "admin_cidr" {
  type = "string"
  description = "The CIDRs where admins will access from."
}

variable "vpc_cidr" {
  type = "string"
  description = "The CIDR block to use for this master-region."

  default = "10.0.0.0/16"
}

variable "master_subnet_cidr" {
  type = "string"
  description = "The CIDR block to use for masters in this region."

  default = "10.0.0.0/18"
}

variable "public_subnet_cidr" {
  type = "string"
  description = "The CIDR block to use for public slaves in this region."

  default = "10.0.64.0/18"
}

variable "private_subnet_cidr" {
  type = "string"
  description = "The CIDR block to use for private slaves in this region."

  default = "10.0.128.0/17"
}

variable "operating_system" {
  type = "string"
  description = "The operating system to use in this region."
}

variable "master_instance_type" {
  type = "string"
  description = "The AWS instance type to use for masters in this region."
}

variable "master_number_of_instances" {
  type = "string"
  description = "The number of masters to run in this region."
}

variable "public_slave_instance_type" {
  type = "string"
  description = "The AWS instance type to use for public slaves."
}

variable "public_slave_number_of_instances" {
  type = "string"
  description = "The number of public slaves to run in this region."
}

variable "private_slave_instance_type" {
  type = "string"
  description = "The AWS instance type to use for private slaves."
}

variable "private_slave_number_of_instances" {
  type = "string"
  description = "The number of private slaves to run in this region."
}
