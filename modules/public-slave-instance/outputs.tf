output "instances" {
  value = ["${aws_instance.public-slave.*.id}"]
}
