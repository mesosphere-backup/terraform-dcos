output "${var.region}-public_slave_elb_dns_name" {
  value = "${aws_elb.public-slave-elb.dns_name}"
}
