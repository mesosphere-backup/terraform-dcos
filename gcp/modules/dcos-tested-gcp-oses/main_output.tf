# Main Output
output "os-setup" {
   value = "${data.template_file.os-setup.rendered}"
}
