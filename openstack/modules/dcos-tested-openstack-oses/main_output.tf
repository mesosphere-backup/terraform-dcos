# Main Output

output "os_setup" {
  value = "${data.template_file.os_setup.rendered}"
}

output "os_user_data" {
  value = "${data.template_file.os_user_data.rendered}"
}

output "user" {
  value = "${data.template_file.traditional_os_user.rendered}"
}
