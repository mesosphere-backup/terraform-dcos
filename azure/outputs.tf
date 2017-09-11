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
