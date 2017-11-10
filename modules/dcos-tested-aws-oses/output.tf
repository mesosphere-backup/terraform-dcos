output "user" {
   value = "${data.template_file.aws_ami_user.rendered}"
 }

output "aws_ami" {
   value = "${data.template_file.aws_ami.rendered}"
}

output "os-setup" {
   value = "${data.template_file.os-setup.rendered}"
}
