output "Private Agent Public IPs" {
  value = ["${aws_instance.agent.*.public_ip}"]
}

output "Bootstrap Host Public IP" {
  value = "${aws_instance.bootstrap.public_ip}"
}

output "GPU Public IPs" {
  value = ["${aws_instance.gpu-agent.*.public_ip}"]
}

output "Master ELB Public IP" {
  value = "${aws_elb.public-master-elb.dns_name}"
}

output "Master Public IPs" {
  value = ["${aws_instance.master.*.public_ip}"]
}

output "Public Agent ELB Public IP" {
  value = "${aws_elb.public-agent-elb.dns_name}"
}

output "Public Agent Public IPs" {
  value = ["${aws_instance.public-agent.*.public_ip}"]
}

output "ssh_user" {
   value = "${module.aws-tested-oses.user}"
}
