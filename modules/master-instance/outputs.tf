output "instances" {
  value = ["${aws_instance.master.*.id}"]
}
