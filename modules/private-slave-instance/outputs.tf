output "instances" {
  value = ["${aws_instance.private-slave.*.id}"]
}
