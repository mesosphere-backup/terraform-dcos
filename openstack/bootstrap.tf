# Bootstrap Node


resource "openstack_networking_floatingip_v2" "bootstrap" {
  pool = "${var.os_floating_ip_pool}"
}

resource "openstack_compute_floatingip_associate_v2" "bootstrap" {
  floating_ip = "${openstack_networking_floatingip_v2.bootstrap.address}"
  instance_id = "${openstack_compute_instance_v2.bootstrap.id}"
}

# Select boot node VM type
data "openstack_compute_flavor_v2" "bootstrap" {
  name = "${var.bootstrap_instance_flavor}"
}


# Create bootstrap security group
resource "openstack_networking_secgroup_v2" "bootstrap_security_group" {
  name = "${data.template_file.cluster-name.rendered}-bootstrap-security-group"
}

resource "openstack_networking_secgroup_rule_v2" "bootstrap_secgroup_rule_ingress" {
  direction         = "ingress"
  ethertype         = "IPv4"
  security_group_id = "${openstack_networking_secgroup_v2.bootstrap_security_group.id}"
}


resource "openstack_networking_port_v2" "bootstrap_port" {
  name                  = "${data.template_file.cluster-name.rendered}-bootstrap-port"
  network_id            = "${openstack_networking_network_v2.vnet.id}"
  admin_state_up        = "true"
  security_group_ids    = ["${openstack_networking_secgroup_v2.bootstrap_security_group.id}"]

  fixed_ip {
    subnet_id           = "${openstack_networking_subnet_v2.public.id}"
  }
}


resource "openstack_compute_instance_v2" "bootstrap" {
  name              = "${data.template_file.cluster-name.rendered}-bootstrap"
  image_id          = "${data.openstack_images_image_v2.selected_image.id}"
  flavor_id         = "${data.openstack_compute_flavor_v2.bootstrap.id}"
  key_pair          = "${openstack_compute_keypair_v2.keypair.name}"
  user_data         = "${module.openstack-tested-oses.os_user_data}"

  metadata {
    Name       = "${coalesce(var.owner, data.external.whoami.result["owner"])}"
    expiration = "${var.expiration}"
  }

  network {
    port = "${openstack_networking_port_v2.bootstrap_port.id}"
  }

}


# Create DCOS Mesos Bootstrap Scripts to execute
module "dcos-bootstrap" {
  source  = "github.com/dcos/tf_dcos_core"
  bootstrap_private_ip = "${openstack_compute_instance_v2.bootstrap.access_ip_v4}"
  # Only allow upgrade and install as installation mode
  dcos_install_mode = "${var.state == "upgrade" ? "upgrade" : "install"}"
  dcos_version = "${var.dcos_version}"
  role = "dcos-bootstrap"
  dcos_bootstrap_port = "${var.custom_dcos_bootstrap_port}"
  custom_dcos_download_path = "${var.custom_dcos_download_path}"
  # TODO(bernadinm) Terraform Bug: 9488.  Templates will not accept list, but only strings.
  # Workaround is to flatten the list as a string below. Fix when this is closed.
  dcos_public_agent_list = "\n - ${join("\n - ", openstack_compute_instance_v2.public_agents.*.access_ip_v4)}"
  dcos_audit_logging = "${var.dcos_audit_logging}"
  dcos_auth_cookie_secure_flag = "${var.dcos_auth_cookie_secure_flag}"
  dcos_aws_access_key_id = "${var.dcos_aws_access_key_id}"
  dcos_aws_region = "${var.dcos_aws_region}"
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
  # TODO: Revisit, implement exhibitor
  dcos_exhibitor_address = ""
  dcos_exhibitor_explicit_keys = "${var.dcos_exhibitor_explicit_keys}"
  dcos_exhibitor_storage_backend = "${var.dcos_exhibitor_storage_backend}"
  dcos_exhibitor_zk_hosts = "${var.dcos_exhibitor_zk_hosts}"
  dcos_exhibitor_zk_path = "${var.dcos_exhibitor_zk_path}"
  dcos_gc_delay = "${var.dcos_gc_delay}"
  dcos_http_proxy = "${var.dcos_http_proxy}"
  dcos_https_proxy = "${var.dcos_https_proxy}"
  dcos_log_directory = "${var.dcos_log_directory}"
  # TODO: Revisit, implement external load balancer "dcos_master_external_loadbalancer"
  dcos_master_discovery = "${var.dcos_master_discovery}"
  dcos_master_dns_bindall = "${var.dcos_master_dns_bindall}"
  # TODO(bernadinm) Terraform Bug: 9488.  Templates will not accept list, but only strings.
  # Workaround is to flatten the list as a string below. Fix when this is closed.
  dcos_master_list = "\n - ${join("\n - ", openstack_compute_instance_v2.masters.*.access_ip_v4)}"
  dcos_no_proxy = "${var.dcos_no_proxy}"
  dcos_num_masters = "${var.num_of_masters}"
  dcos_oauth_enabled = "${var.dcos_oauth_enabled}"
  dcos_overlay_config_attempts = "${var.dcos_overlay_config_attempts}"
  dcos_overlay_enable = "${var.dcos_overlay_enable}"
  dcos_overlay_mtu = "${var.dcos_overlay_mtu}"
  dcos_overlay_network = "${var.dcos_overlay_network}"
  dcos_process_timeout = "${var.dcos_process_timeout}"
  dcos_previous_version = "${var.dcos_previous_version}"
  dcos_agent_list = "\n - ${join("\n - ", openstack_compute_instance_v2.private_agents.*.access_ip_v4)}"
  # TODO(bernadinm) Terraform Bug: 9488.  Templates will not accept list, but only strings.
  # Workaround is to flatten the list as a string below. Fix when this is closed.
  dcos_resolvers  = "\n - ${join("\n - ", var.dcos_resolvers)}"
  dcos_rexray_config_filename = "${var.dcos_rexray_config_filename}"
  dcos_rexray_config_method = "${var.dcos_rexray_config_method}"
  dcos_s3_bucket = "${var.dcos_s3_bucket}"
  dcos_s3_prefix = "${var.dcos_s3_prefix}"
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
  dcos_config = "${var.dcos_config}"
}

resource "null_resource" "bootstrap" {
  # If state is set to none do not install DC/OS
  count = "${var.state == "none" ? 0 : 1}"
  # Changes to any instance of the cluster requires re-provisioning
  triggers {
    cluster_instance_ids = "${openstack_compute_instance_v2.bootstrap.id}"
    dcos_version = "${var.dcos_version}"
    dcos_security = "${var.dcos_security}"
    num_of_masters = "${var.num_of_masters}"
    dcos_bootstrap_port = "${var.custom_dcos_bootstrap_port}"
    dcos_audit_logging = "${var.dcos_audit_logging}"
    dcos_auth_cookie_secure_flag = "${var.dcos_auth_cookie_secure_flag}"
    dcos_aws_access_key_id = "${var.dcos_aws_access_key_id}"
    dcos_aws_region = "${var.dcos_aws_region}"
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
    # TODO: Revisit, implement exhibitor
    dcos_exhibitor_address = ""
    dcos_exhibitor_explicit_keys = "${var.dcos_exhibitor_explicit_keys}"
    dcos_exhibitor_storage_backend = "${var.dcos_exhibitor_storage_backend}"
    dcos_exhibitor_zk_hosts = "${var.dcos_exhibitor_zk_hosts}"
    dcos_exhibitor_zk_path = "${var.dcos_exhibitor_zk_path}"
    dcos_gc_delay = "${var.dcos_gc_delay}"
    dcos_http_proxy = "${var.dcos_http_proxy}"
    dcos_https_proxy = "${var.dcos_https_proxy}"
    dcos_log_directory = "${var.dcos_log_directory}"
    # TODO: Revisit, implement external load balancer "dcos_master_external_loadbalancer"
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
    # TODO(bernadinm) Terraform Bug: 9488.  Templates will not accept list, but only strings.
    # Workaround is to flatten the list as a string below. Fix when this is closed.
    dcos_previous_version = "${var.dcos_previous_version}"
    dcos_resolvers  = "\n - ${join("\n - ", var.dcos_resolvers)}"
    dcos_rexray_config_filename = "${var.dcos_rexray_config_filename}"
    dcos_rexray_config_method = "${var.dcos_rexray_config_method}"
    dcos_s3_bucket = "${var.dcos_s3_bucket}"
    dcos_s3_prefix = "${var.dcos_s3_prefix}"
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
    dcos_config = "${var.dcos_config}"
  }

  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    host = "${openstack_networking_floatingip_v2.bootstrap.address}"
    user = "${coalesce(var.admin_username, module.openstack-tested-oses.user)}"
    private_key = "${local.private_key}"
    agent = "${local.agent}"
  }

  # DCOS ip detect script
  provisioner "file" {
   source = "${var.ip-detect}"
   destination = "/tmp/ip-detect"
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


output "Bootstrap Host Public IP" {
  value = "${openstack_networking_floatingip_v2.bootstrap.address}"
}
