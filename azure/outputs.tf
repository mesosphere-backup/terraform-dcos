output "Master_ELB_Address" {
  value = "${azurerm_public_ip.master_load_balancer_public_ip.fqdn}"
}

output "Public_Agent_ELB_Address" {
  value = "${azurerm_public_ip.public_agent_load_balancer_public_ip.fqdn}"
}

output "Mesos_Master_Public_IP" {
  value = ["${azurerm_public_ip.master_public_ip.*.fqdn}"]
}

output "Private_Agent_Public_IP_Address" {
  value = ["${azurerm_public_ip.agent_public_ip.*.fqdn}"]
}

output "Public_Agent_Public_IP_Address" {
  value = ["${azurerm_public_ip.public_agent_public_ip.*.fqdn}"]
}

output "Bootstrap_Public_IP_Address" {
  value = "${azurerm_public_ip.bootstrap_public_ip.fqdn}"
}
