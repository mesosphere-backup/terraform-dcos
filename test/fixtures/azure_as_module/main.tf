module "dcos_cluster_azure" {
  source                         = "../../../azure"
  dcos_version                   = "${var.dcos_version}"
  azure_region                     = "${var.azure_region}"
  num_of_masters                 = "${var.num_of_masters}"
  num_of_public_agents           = "${var.num_of_public_agents}"
  num_of_private_agents          = "${var.num_of_private_agents}"
  dcos_master_discovery = "${var.dcos_master_discovery}"
  dcos_exhibitor_storage_backend = "${var.dcos_exhibitor_storage_backend}"
}
