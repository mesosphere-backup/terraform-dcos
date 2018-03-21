output "Master ELB Public IP" {
  value = "${azurerm_public_ip.master_load_balancer_public_ip.fqdn}"
}

output "Public Agent ELB Public IP" {
  value = "${azurerm_public_ip.public_agent_load_balancer_public_ip.fqdn}"
}

output "Master Public IPs" {
  value = ["${azurerm_public_ip.master_public_ip.*.fqdn}"]
}

output "Private Agent Public IPs" {
  value = ["${azurerm_public_ip.agent_public_ip.*.fqdn}"]
}

output "Public Agent Public IPs" {
  value = ["${azurerm_public_ip.public_agent_public_ip.*.fqdn}"]
}

output "Bootstrap Host Public IP" {
  value = "${azurerm_public_ip.bootstrap_public_ip.fqdn}"
}

output "ssh_user" {
 value = "${module.azure-tested-oses.user}"
}
