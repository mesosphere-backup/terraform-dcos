#output "SSH Name" {
# value = "${var.gce_ssh_user}@${google_compute_instance.vm.network_interface.0.access_config.0.assigned_nat_ip}"
#}
