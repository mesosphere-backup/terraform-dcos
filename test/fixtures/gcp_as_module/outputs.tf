output "master_elb_public_ip" {
  value = "${module.dcos_cluster_gcp.master_elb_public_ip}"
}

output "bootstrap_host_public_ip" {
  value = "${module.dcos_cluster_gcp.bootstrap_host_public_ip}"
}

output "master_public_ips" {
  value = "${module.dcos_cluster_gcp.master_public_ips}"
}

output "private_agent_public_ips" {
  value = "${module.dcos_cluster_gcp.private_agent_public_ips}"
}

output "public_agent_elb_public_ip" {
  value = "${module.dcos_cluster_gcp.public_agent_elb_public_ip}"
}

output "public_agent_public_ip" {
  value = "${module.dcos_cluster_gcp.public_agent_public_ip}"
}

output "ssh_user" {
  value = "${module.dcos_cluster_gcp.ssh_user}"
}
