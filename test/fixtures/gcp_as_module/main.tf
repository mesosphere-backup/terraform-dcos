module "dcos_cluster_gcp" {
  source                         = "../../../gcp"
  dcos_version                   = "${var.dcos_version}"
  gcp_zone                     = "${var.gcp_zone}"
  admin_cidr                     = "${var.admin_cidr}"
  gcp_master_instance_type       = "${var.gcp_master_instance_type}"
  gcp_agent_instance_type        = "${var.gcp_agent_instance_type}"
  gcp_public_agent_instance_type = "${var.gcp_public_agent_instance_type}"
  gcp_bootstrap_instance_type    = "${var.gcp_bootstrap_instance_type}"
  num_of_masters                 = "${var.num_of_masters}"
  num_of_public_agents           = "${var.num_of_public_agents}"
  num_of_private_agents          = "${var.num_of_private_agents}"
}
