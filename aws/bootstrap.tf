# Deploy the bootstrap instance
resource "aws_instance" "bootstrap" {
  # The connection block tells our provisioner how to
  # communicate with the resource (instance)
  connection {
    # The default username for our AMI
    user = "${module.aws-tested-oses.user}"

    # The connection will use the local SSH agent for authentication.
  }

  root_block_device {
    volume_size = "${var.aws_bootstrap_instance_disk_size}"
  }

  instance_type = "${var.aws_bootstrap_instance_type}"

  tags {
   owner = "${coalesce(var.owner, data.external.whoami.result["owner"])}"
   expiration = "${var.expiration}"
   Name = "${data.template_file.cluster-name.rendered}-bootstrap"
   cluster = "${data.template_file.cluster-name.rendered}"
  }

  # Lookup the correct AMI based on the region
  # we specified
  ami = "${module.aws-tested-oses.aws_ami}"

  # The name of our SSH keypair we created above.
  key_name = "${var.ssh_key_name}"

  # Our Security group to allow http and SSH access
  vpc_security_group_ids = ["${aws_security_group.any_access_internal.id}","${aws_security_group.admin.id}"]

  # We're going to launch into the same subnet as our ELB. In a production
  # environment it's more common to have a separate private subnet for
  # backend instances.
  subnet_id = "${aws_subnet.public.id}"

  # DCOS ip detect script
  provisioner "file" {
   source = "${var.ip-detect["aws"]}"
   destination = "/tmp/ip-detect"
   }

  # OS init script
  provisioner "file" {
   content = "${module.aws-tested-oses.os-setup}"
   destination = "/tmp/os-setup.sh"
   }

 # We run a remote provisioner on the instance after creating it.
  # In this case, we just install nginx and start it. By default,
  # this should be on port 80
    provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/os-setup.sh",
      "sudo bash /tmp/os-setup.sh",
    ]
  }

  lifecycle {
    ignore_changes = ["tags.Name"]
  }
}


# Create DCOS Mesos Master Scripts to execute
  module "dcos-bootstrap" {
    source = "github.com/dcos/tf_dcos_core"
    bootstrap_private_ip = "${aws_instance.bootstrap.private_ip}"
    # Only allow upgrade and install as installation mode
    dcos_install_mode = "${var.state == "upgrade" ? "upgrade" : "install"}"
    dcos_version = "${var.dcos_version}"
    role = "dcos-bootstrap"
    dcos_bootstrap_port = "${var.custom_dcos_bootstrap_port}"
    custom_dcos_download_path = "${var.custom_dcos_download_path}"
    # TODO(bernadinm) Terraform Bug: 9488.  Templates will not accept list, but only strings.
    # Workaround is to flatten the list as a string below. Fix when this is closed.
    dcos_public_agent_list = "\n - ${join("\n - ", aws_instance.public-agent.*.private_ip)}"
    dcos_audit_logging = "${var.dcos_audit_logging}"
    dcos_auth_cookie_secure_flag = "${var.dcos_auth_cookie_secure_flag}"
    dcos_aws_access_key_id = "${var.dcos_aws_access_key_id}"
    dcos_aws_region = "${coalesce(var.dcos_aws_region, var.aws_region)}"
    dcos_aws_secret_access_key = "${var.dcos_aws_secret_access_key}"
    dcos_aws_template_storage_access_key_id = "${var.dcos_aws_template_storage_access_key_id}"
    dcos_aws_template_storage_bucket = "${var.dcos_aws_template_storage_bucket}"
    dcos_aws_template_storage_bucket_path = "${var.dcos_aws_template_storage_bucket_path}"
    dcos_aws_template_storage_region_name = "${var.dcos_aws_template_storage_region_name}"
    dcos_aws_template_storage_secret_access_key = "${var.dcos_aws_template_storage_secret_access_key}"
    dcos_aws_template_upload = "${var.dcos_aws_template_upload}"
    dcos_bouncer_expiration_auth_token_days = "${var.dcos_bouncer_expiration_auth_token_days}"
    dcos_check_time = "${var.dcos_check_time}"
    dcos_cluster_docker_credentials = "${var.dcos_cluster_docker_credentials}"
    dcos_cluster_docker_credentials_dcos_owned = "${var.dcos_cluster_docker_credentials_dcos_owned}"
    dcos_cluster_docker_credentials_enabled = "${var.dcos_cluster_docker_credentials_enabled}"
    dcos_cluster_docker_credentials_write_to_etc = "${var.dcos_cluster_docker_credentials_write_to_etc}"
    dcos_cluster_name  = "${coalesce(var.dcos_cluster_name, data.template_file.cluster-name.rendered)}"
    dcos_customer_key = "${var.dcos_customer_key}"
    dcos_dns_search = "${var.dcos_dns_search}"
    dcos_docker_remove_delay = "${var.dcos_docker_remove_delay}"
    dcos_exhibitor_address = "${aws_elb.internal-master-elb.dns_name}"
    dcos_exhibitor_azure_account_key = "${var.dcos_exhibitor_azure_account_key}"
    dcos_exhibitor_azure_account_name = "${var.dcos_exhibitor_azure_account_name}"
    dcos_exhibitor_azure_prefix = "${var.dcos_exhibitor_azure_prefix}"
    dcos_exhibitor_explicit_keys = "${var.dcos_exhibitor_explicit_keys}"
    dcos_exhibitor_storage_backend = "${var.dcos_exhibitor_storage_backend}"
    dcos_exhibitor_zk_hosts = "${var.dcos_exhibitor_zk_hosts}"
    dcos_exhibitor_zk_path = "${var.dcos_exhibitor_zk_path}"
    dcos_gc_delay = "${var.dcos_gc_delay}"
    dcos_http_proxy = "${var.dcos_http_proxy}"
    dcos_https_proxy = "${var.dcos_https_proxy}"
    dcos_log_directory = "${var.dcos_log_directory}"
    dcos_master_external_loadbalancer = "${coalesce(var.dcos_master_external_loadbalancer, aws_elb.public-master-elb.dns_name)}"
    dcos_master_discovery = "${var.dcos_master_discovery}"
    dcos_master_dns_bindall = "${var.dcos_master_dns_bindall}"
    # TODO(bernadinm) Terraform Bug: 9488.  Templates will not accept list, but only strings.
    # Workaround is to flatten the list as a string below. Fix when this is closed.
    dcos_master_list = "\n - ${join("\n - ", aws_instance.master.*.private_ip)}"
    dcos_no_proxy = "${var.dcos_no_proxy}"
    dcos_num_masters = "${var.num_of_masters}"
    dcos_oauth_enabled = "${var.dcos_oauth_enabled}"
    dcos_overlay_config_attempts = "${var.dcos_overlay_config_attempts}"
    dcos_overlay_enable = "${var.dcos_overlay_enable}"
    dcos_overlay_mtu = "${var.dcos_overlay_mtu}"
    dcos_overlay_network = "${var.dcos_overlay_network}"
    dcos_process_timeout = "${var.dcos_process_timeout}"
    dcos_previous_version = "${var.dcos_previous_version}"
    dcos_agent_list = "\n - ${join("\n - ", aws_instance.agent.*.private_ip)}"
    # TODO(bernadinm) Terraform Bug: 9488.  Templates will not accept list, but only strings.
    # Workaround is to flatten the list as a string below. Fix when this is closed.
    dcos_resolvers  = "\n - ${join("\n - ", var.dcos_resolvers)}"
    dcos_rexray_config_filename = "${var.dcos_rexray_config_filename}"
    dcos_rexray_config_method = "${var.dcos_rexray_config_method}"
    dcos_s3_bucket = "${coalesce(var.dcos_s3_bucket, aws_s3_bucket.dcos_bucket.id)}"
    dcos_s3_prefix = "${coalesce(var.dcos_s3_prefix, aws_s3_bucket.dcos_bucket.id)}"
    dcos_security  = "${var.dcos_security}"
    dcos_superuser_password_hash = "${var.dcos_superuser_password_hash}"
    dcos_superuser_username = "${var.dcos_superuser_username}"
    dcos_telemetry_enabled = "${var.dcos_telemetry_enabled}"
    dcos_use_proxy = "${var.dcos_use_proxy}"
    dcos_zk_agent_credentials = "${var.dcos_zk_agent_credentials}"
    dcos_zk_master_credentials = "${var.dcos_zk_master_credentials}"
    dcos_zk_super_credentials = "${var.dcos_zk_super_credentials}"
    dcos_cluster_docker_registry_url = "${var.dcos_cluster_docker_registry_url}"
    dcos_rexray_config = "${var.dcos_rexray_config}"
    dcos_ip_detect_public_contents = "${var.dcos_ip_detect_public_contents}"
    dcos_enable_docker_gc = "${var.dcos_enable_docker_gc}"
    dcos_staged_package_storage_uri = "${var.dcos_staged_package_storage_uri}"
    dcos_package_storage_uri = "${var.dcos_package_storage_uri}"
 }

resource "null_resource" "bootstrap" {
  # If state is set to none do not install DC/OS
  count = "${var.state == "none" ? 0 : 1}"
  # Changes to any instance of the cluster requires re-provisioning
  triggers {
    cluster_instance_ids = "${aws_instance.bootstrap.id}"
    dcos_version = "${var.dcos_version}"
    dcos_security = "${var.dcos_security}"
    num_of_masters = "${var.num_of_masters}"
    dcos_audit_logging = "${var.dcos_audit_logging}"
    dcos_auth_cookie_secure_flag = "${var.dcos_auth_cookie_secure_flag}"
    dcos_aws_access_key_id = "${var.dcos_aws_access_key_id}"
    dcos_aws_region = "${coalesce(var.dcos_aws_region, var.aws_region)}"
    dcos_aws_secret_access_key = "${var.dcos_aws_secret_access_key}"
    dcos_aws_template_storage_access_key_id = "${var.dcos_aws_template_storage_access_key_id}"
    dcos_aws_template_storage_bucket = "${var.dcos_aws_template_storage_bucket}"
    dcos_aws_template_storage_bucket_path = "${var.dcos_aws_template_storage_bucket_path}"
    dcos_aws_template_storage_region_name = "${var.dcos_aws_template_storage_region_name}"
    dcos_aws_template_storage_secret_access_key = "${var.dcos_aws_template_storage_secret_access_key}"
    dcos_aws_template_upload = "${var.dcos_aws_template_upload}"
    dcos_bouncer_expiration_auth_token_days = "${var.dcos_bouncer_expiration_auth_token_days}"
    dcos_check_time = "${var.dcos_check_time}"
    dcos_cluster_docker_credentials = "${var.dcos_cluster_docker_credentials}"
    dcos_cluster_docker_credentials_dcos_owned = "${var.dcos_cluster_docker_credentials_dcos_owned}"
    dcos_cluster_docker_credentials_enabled = "${var.dcos_cluster_docker_credentials_enabled}"
    dcos_cluster_docker_credentials_write_to_etc = "${var.dcos_cluster_docker_credentials_write_to_etc}"
    dcos_cluster_name  = "${coalesce(var.dcos_cluster_name, data.template_file.cluster-name.rendered)}"
    dcos_customer_key = "${var.dcos_customer_key}"
    dcos_dns_search = "${var.dcos_dns_search}"
    dcos_docker_remove_delay = "${var.dcos_docker_remove_delay}"
    dcos_exhibitor_address = "${aws_elb.internal-master-elb.dns_name}"
    dcos_exhibitor_azure_account_key = "${var.dcos_exhibitor_azure_account_key}"
    dcos_exhibitor_azure_account_name = "${var.dcos_exhibitor_azure_account_name}"
    dcos_exhibitor_azure_prefix = "${var.dcos_exhibitor_azure_prefix}"
    dcos_exhibitor_explicit_keys = "${var.dcos_exhibitor_explicit_keys}"
    dcos_exhibitor_storage_backend = "${var.dcos_exhibitor_storage_backend}"
    dcos_exhibitor_zk_hosts = "${var.dcos_exhibitor_zk_hosts}"
    dcos_exhibitor_zk_path = "${var.dcos_exhibitor_zk_path}"
    dcos_gc_delay = "${var.dcos_gc_delay}"
    dcos_http_proxy = "${var.dcos_http_proxy}"
    dcos_https_proxy = "${var.dcos_https_proxy}"
    dcos_log_directory = "${var.dcos_log_directory}"
    dcos_master_external_loadbalancer = "${coalesce(var.dcos_master_external_loadbalancer, aws_elb.public-master-elb.dns_name)}"
    dcos_master_discovery = "${var.dcos_master_discovery}"
    dcos_master_dns_bindall = "${var.dcos_master_dns_bindall}"
    # TODO(bernadinm) Terraform Bug: 9488.  Templates will not accept list, but only strings.
    # Workaround is to flatten the list as a string below. Fix when this is closed.
    dcos_no_proxy = "${var.dcos_no_proxy}"
    dcos_num_masters = "${var.num_of_masters}"
    dcos_oauth_enabled = "${var.dcos_oauth_enabled}"
    dcos_overlay_config_attempts = "${var.dcos_overlay_config_attempts}"
    dcos_overlay_enable = "${var.dcos_overlay_enable}"
    dcos_overlay_mtu = "${var.dcos_overlay_mtu}"
    dcos_overlay_network = "${var.dcos_overlay_network}"
    dcos_process_timeout = "${var.dcos_process_timeout}"
    dcos_previous_version = "${var.dcos_previous_version}"
    # TODO(bernadinm) Terraform Bug: 9488.  Templates will not accept list, but only strings.
    # Workaround is to flatten the list as a string below. Fix when this is closed.
    dcos_resolvers  = "\n - ${join("\n - ", var.dcos_resolvers)}"
    dcos_rexray_config_filename = "${var.dcos_rexray_config_filename}"
    dcos_rexray_config_method = "${var.dcos_rexray_config_method}"
    dcos_s3_bucket = "${coalesce(var.dcos_s3_bucket, aws_s3_bucket.dcos_bucket.id)}"
    dcos_s3_prefix = "${coalesce(var.dcos_s3_prefix, aws_s3_bucket.dcos_bucket.id)}"
    dcos_security  = "${var.dcos_security}"
    dcos_superuser_password_hash = "${var.dcos_superuser_password_hash}"
    dcos_superuser_username = "${var.dcos_superuser_username}"
    dcos_telemetry_enabled = "${var.dcos_telemetry_enabled}"
    dcos_use_proxy = "${var.dcos_use_proxy}"
    dcos_zk_agent_credentials = "${var.dcos_zk_agent_credentials}"
    dcos_zk_master_credentials = "${var.dcos_zk_master_credentials}"
    dcos_zk_super_credentials = "${var.dcos_zk_super_credentials}"
    dcos_cluster_docker_registry_url = "${var.dcos_cluster_docker_registry_url}"
    dcos_rexray_config = "${var.dcos_rexray_config}"
    dcos_ip_detect_public_contents = "${var.dcos_ip_detect_public_contents}"
    dcos_enable_docker_gc = "${var.dcos_enable_docker_gc}"
    dcos_staged_package_storage_uri = "${var.dcos_staged_package_storage_uri}"
    dcos_package_storage_uri = "${var.dcos_package_storage_uri}"
  }

  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    host = "${element(aws_instance.bootstrap.*.public_ip, 0)}"
    user = "${module.aws-tested-oses.user}"
  }

  # Generate and upload bootstrap script to node
  provisioner "file" {
    content     = "${module.dcos-bootstrap.script}"
    destination = "run.sh"
  }

  # Install Bootstrap Script
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x run.sh",
      "sudo ./run.sh",
    ]
  }

  lifecycle {
    ignore_changes = ["data.template_file.cluster-name.rendered"]
  }
}

output "Bootstrap Public IP Address" {
  value = "${aws_instance.bootstrap.public_ip}"
}
