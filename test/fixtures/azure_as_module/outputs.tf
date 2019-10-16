output "master_elb_public_ip" {
  value = "${module.dcos_cluster_azure.master_elb_public_ip}"
}

output "bootstrap_host_public_ip" {
  value = "${module.dcos_cluster_azure.bootstrap_host_public_ip}"
}

output "master_public_ips" {
  value = "${module.dcos_cluster_azure.master_public_ips}"
}

output "private_agent_public_ips" {
  value = "${module.dcos_cluster_azure.private_agent_public_ips}"
}

output "public_agent_elb_public_ip" {
  value = "${module.dcos_cluster_azure.public_agent_elb_public_ip}"
}

output "public_agent_public_ip" {
  value = "${module.dcos_cluster_azure.public_agent_public_ip}"
}

output "ssh_user" {
  value = "${module.dcos_cluster_azure.ssh_user}"
}
