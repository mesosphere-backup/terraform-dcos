variable "cluster_id" {
  type = "string"
  description = "An identifier for this cluster."
}

variable "bootstrap_user" {
  type = "string"
  description = "The user that will be used to set up the bootstrap node."
}

variable "bootstrap_serve_port" {
  type = "string"
  description = "The port to run the bootstrap webserver on. Should not collide with DC/OS internal ports."

  default = "3080"
}

variable "master_list" {
  type = "list"
  description = "A list of master id's."
}
