output "address" {
  value = "${aws_elb.public-master-elb.dns_name}"
}
