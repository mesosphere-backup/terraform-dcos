output "bootstrap_serve_ip" {
  value = "${data.aws_instance.bootstrap-node.private_ip}"
}

output "bootstrap_serve_port" {
  value = "${var.bootstrap_serve_port}"
}
