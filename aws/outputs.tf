output "Master ELB Address" {
  value = "${aws_elb.public-master-elb.dns_name}"
}

output "Mesos Master Public IP" {
  value = ["${aws_instance.master.*.public_ip}"]
}

output "Private Agent Public IP Address" {
  value = ["${aws_instance.agent.*.public_ip}"]
}

output "Public Agent Public IP Address" {
  value = ["${aws_instance.public-agent.*.public_ip}"]
}
