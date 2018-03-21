output "Private Agent Public IPs" {
  value = ["${google_compute_instance.agent.*.network_interface.0.access_config.0.assigned_nat_ip}"]
}

output "Bootstrap Host Public IP" {
  value = "${google_compute_instance.bootstrap.network_interface.0.access_config.0.assigned_nat_ip}"
}

output "Master ELB Public IP" {
  value = "${google_compute_forwarding_rule.external-master-forwarding-rule-http.ip_address}"
}

output "Master Public IPs" {
  value = ["${google_compute_instance.master.*.network_interface.0.access_config.0.assigned_nat_ip}"]
}

output "Public Agent ELB Public IP" {
  value = "${google_compute_forwarding_rule.external-public-agent-forwarding-rule-http.ip_address}"
}

output "Public Agent Public IPs" {
  value = ["${google_compute_instance.public-agent.*.network_interface.0.access_config.0.assigned_nat_ip}"]
}

output "ssh_user" {
 value = "${module.dcos-tested-gcp-oses.user}"
}
