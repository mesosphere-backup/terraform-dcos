output "master_elb_public_ip" {
  value = "${module.dcos_cluster_aws.master_elb_public_ip}"
}

output "bootstrap_host_public_ip" {
  value = "${module.dcos_cluster_aws.bootstrap_host_public_ip}"
}

output "master_public_ips" {
  value = "${module.dcos_cluster_aws.master_public_ips}"
}

output "private_agent_public_ips" {
  value = "${module.dcos_cluster_aws.private_agent_public_ips}"
}

output "public_agent_elb_public_ip" {
  value = "${module.dcos_cluster_aws.public_agent_elb_public_ip}"
}

output "public_agent_public_ip" {
  value = "${module.dcos_cluster_aws.public_agent_public_ips}"
}

output "ssh_user" {
  value = "${module.dcos_cluster_aws.ssh_user}"
}
