output "Master ELB Address" {
  value = "${azurerm_public_ip.master_load_balancer_public_ip.fqdn}"
}

output "Public Agent ELB Address" {
  value = "${azurerm_public_ip.public_agent_load_balancer_public_ip.fqdn}"
}

output "Mesos Master Public IP" {
  value = ["${azurerm_public_ip.master_public_ip.*.fqdn}"]
}

output "Private Agent Public IP Address" {
  value = ["${azurerm_public_ip.agent_public_ip.*.fqdn}"]
}

output "Public Agent Public IP Address" {
  value = ["${azurerm_public_ip.public_agent_public_ip.*.fqdn}"]
}

output "Bootstrap Public IP Address" {
  value = "${azurerm_public_ip.bootstrap_public_ip.fqdn}"
}

output "Internal Master ELB Address" {
  value = "${azurerm_lb.master_internal_load_balancer.private_ip_address}"
}

output "DNS Search" {
  value = "None"
}

output "DNS Resolvers" {
  value = "${var.dcos_resolvers}"
}

output "Mesos Master Private IP" {
  value = "${azurerm_network_interface.master_nic.*.private_ip_address}"
}

output "Bootstrap Private IP Address" {
  value = "${azurerm_network_interface.bootstrap_nic.private_ip_address}"
}

output "Cluster Prefix" {
  value = "${data.template_file.cluster-name.rendered}"
}
