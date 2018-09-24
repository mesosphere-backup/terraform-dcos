# Bootstrap Node
resource "azurerm_managed_disk" "bootstrap_managed_disk" {
  name                 = "${data.template_file.cluster-name.rendered}-bootstrap"
  location             = "${var.azure_region}"
  resource_group_name  = "${azurerm_resource_group.dcos.name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "${var.instance_disk_size}"
}

# Public IP addresses for the Public Front End load Balancer
resource "azurerm_public_ip" "bootstrap_public_ip" {
  name                         = "${data.template_file.cluster-name.rendered}-bootstrap-pub-ip"
  location                     = "${var.azure_region}"
  resource_group_name          = "${azurerm_resource_group.dcos.name}"
  public_ip_address_allocation = "dynamic"
  domain_name_label = "${data.template_file.cluster-name.rendered}-bootstrap"

  tags {
   Name       = "${coalesce(var.owner, data.external.whoami.result["owner"])}"
   expiration = "${var.expiration}"
  }
}

# Bootstrap Security Groups for NICs
resource "azurerm_network_security_group" "bootstrap_security_group" {
    name = "${data.template_file.cluster-name.rendered}-bootstrap-security-group"
    location = "${var.azure_region}"
    resource_group_name = "${azurerm_resource_group.dcos.name}"

    tags {
      Name       = "${coalesce(var.owner, data.external.whoami.result["owner"])}"
      expiration = "${var.expiration}"
  }
}

resource "azurerm_network_security_rule" "bootstrap-sshRule" {
    name                        = "sshRule"
    priority                    = 100
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_range      = "22"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
    resource_group_name         = "${azurerm_resource_group.dcos.name}"
    network_security_group_name = "${azurerm_network_security_group.bootstrap_security_group.name}"
}


resource "azurerm_network_security_rule" "bootstrap-httpRule" {
    name                        = "HTTP"
    priority                    = 110
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_range      = "80"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
    resource_group_name         = "${azurerm_resource_group.dcos.name}"
    network_security_group_name = "${azurerm_network_security_group.bootstrap_security_group.name}"
}

resource "azurerm_network_security_rule" "bootstrap-httpsRule" {
    name                        = "HTTPS"
    priority                    = 120
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_range      = "443"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
    resource_group_name         = "${azurerm_resource_group.dcos.name}"
    network_security_group_name = "${azurerm_network_security_group.bootstrap_security_group.name}"
}

resource "azurerm_network_security_rule" "bootstrap-internalEverything" {
    name                        = "allOtherInternalTraffric"
    priority                    = 160
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_range      = "*"
    source_address_prefix       = "VirtualNetwork"
    destination_address_prefix  = "*"
    resource_group_name         = "${azurerm_resource_group.dcos.name}"
    network_security_group_name = "${azurerm_network_security_group.bootstrap_security_group.name}"
}

resource "azurerm_network_security_rule" "bootstrap-everythingElseOutBound" {
    name                        = "allOtherTrafficOutboundRule"
    priority                    = 170
    direction                   = "Outbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "*"
    destination_port_range      = "*"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
    resource_group_name         = "${azurerm_resource_group.dcos.name}"
    network_security_group_name = "${azurerm_network_security_group.bootstrap_security_group.name}"
}

# End of Bootstrap NIC Security Group

# Bootstrap NICs with Security Group
resource "azurerm_network_interface" "bootstrap_nic" {
  name                      = "${data.template_file.cluster-name.rendered}-bootstrap-nic"
  location                  = "${var.azure_region}"
  resource_group_name       = "${azurerm_resource_group.dcos.name}"
  network_security_group_id = "${azurerm_network_security_group.bootstrap_security_group.id}"

  ip_configuration {
   name                                    = "${data.template_file.cluster-name.rendered}-bootstrap-ipConfig"
   subnet_id                               = "${azurerm_subnet.public.id}"
   private_ip_address_allocation           = "dynamic"
   public_ip_address_id                    = "${azurerm_public_ip.bootstrap_public_ip.id}"
  }

  tags {
   Name       = "${coalesce(var.owner, data.external.whoami.result["owner"])}"
   expiration = "${var.expiration}"
  }
}

# Bootstrap VM Coniguration
resource "azurerm_virtual_machine" "bootstrap" {
    name                             = "${data.template_file.cluster-name.rendered}-bootstrap"
    location                         = "${var.azure_region}"
    resource_group_name              = "${azurerm_resource_group.dcos.name}"
    network_interface_ids            = ["${azurerm_network_interface.bootstrap_nic.id}"]
    vm_size                          = "${var.azure_bootstrap_instance_type}"
    delete_os_disk_on_termination    = true
    delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "${module.azure-tested-oses.azure_publisher}"
    offer     = "${module.azure-tested-oses.azure_offer}"
    sku       = "${module.azure-tested-oses.azure_sku}"
    version   = "${module.azure-tested-oses.azure_version}"
  }

  storage_os_disk {
    name              = "os-disk-bootstrap"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name            = "${azurerm_managed_disk.bootstrap_managed_disk.name}"
    managed_disk_id = "${azurerm_managed_disk.bootstrap_managed_disk.id}"
    create_option   = "Attach"
    lun             = 0
    disk_size_gb    = "${azurerm_managed_disk.bootstrap_managed_disk.disk_size_gb}"
  }

  os_profile {
    computer_name  = "bootstrap"
    admin_username = "${coalesce(var.azure_admin_username, module.azure-tested-oses.user)}"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
        path     = "/home/${coalesce(var.azure_admin_username, module.azure-tested-oses.user)}/.ssh/authorized_keys"
        key_data = "${var.ssh_pub_key}"
    }
  }

  # OS init script
  provisioner "file" {
   content = "${module.azure-tested-oses.os-setup}"
   destination = "/tmp/os-setup.sh"

   connection {
    type = "ssh"
    user = "${coalesce(var.azure_admin_username, module.azure-tested-oses.user)}"
    host = "${azurerm_public_ip.bootstrap_public_ip.fqdn}"
    private_key = "${local.private_key}"
    agent = "${local.agent}"
    }
 }

 # We run a remote provisioner on the instance after creating it.
  # In this case, we just install nginx and start it. By default,
  # this should be on port 80
    provisioner "remote-exec" {
    inline = [
      "sudo chmod +x /tmp/os-setup.sh",
      "sudo bash /tmp/os-setup.sh",
    ]

   connection {
    type = "ssh"
    user = "${coalesce(var.azure_admin_username, module.azure-tested-oses.user)}"
    host = "${azurerm_public_ip.bootstrap_public_ip.fqdn}"
    private_key = "${local.private_key}"
    agent = "${local.agent}"
   }
 }

  tags {
   Name       = "${coalesce(var.owner, data.external.whoami.result["owner"])}"
   expiration = "${var.expiration}"
 }
}

# Create DCOS Mesos Bootstrap Scripts to execute
  module "dcos-bootstrap" {
    source  = "github.com/dcos/tf_dcos_core"
    bootstrap_private_ip = "${azurerm_network_interface.bootstrap_nic.private_ip_address}"
    # Only allow upgrade and install as installation mode
    dcos_install_mode = "${var.state == "upgrade" ? "upgrade" : "install"}"
    dcos_version = "${var.dcos_version}"
    role = "dcos-bootstrap"
    dcos_bootstrap_port = "${var.custom_dcos_bootstrap_port}"
    custom_dcos_download_path = "${var.custom_dcos_download_path}"
    # TODO(bernadinm) Terraform Bug: 9488.  Templates will not accept list, but only strings.
    # Workaround is to flatten the list as a string below. Fix when this is closed.
    dcos_public_agent_list = "\n - ${join("\n - ", azurerm_network_interface.public_agent_nic.*.private_ip_address)}"
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
    dcos_exhibitor_address = "${azurerm_lb.master_internal_load_balancer.private_ip_address}"
    dcos_exhibitor_azure_account_key = "${coalesce(var.dcos_exhibitor_azure_account_key, azurerm_storage_account.dcos-exhibitor-account.primary_access_key)}"
    dcos_exhibitor_azure_account_name = "${coalesce(var.dcos_exhibitor_azure_account_name, azurerm_storage_account.dcos-exhibitor-account.name)}"
    dcos_exhibitor_azure_prefix = "${coalesce(var.dcos_exhibitor_azure_prefix, data.template_file.cluster-name.rendered)}"
    dcos_exhibitor_explicit_keys = "${var.dcos_exhibitor_explicit_keys}"
    dcos_exhibitor_storage_backend = "${var.dcos_exhibitor_storage_backend}"
    dcos_exhibitor_zk_hosts = "${var.dcos_exhibitor_zk_hosts}"
    dcos_exhibitor_zk_path = "${var.dcos_exhibitor_zk_path}"
    dcos_gc_delay = "${var.dcos_gc_delay}"
    dcos_http_proxy = "${var.dcos_http_proxy}"
    dcos_https_proxy = "${var.dcos_https_proxy}"
    dcos_log_directory = "${var.dcos_log_directory}"
    dcos_master_external_loadbalancer = "${coalesce(var.dcos_master_external_loadbalancer, azurerm_public_ip.master_load_balancer_public_ip.fqdn)}"
    dcos_master_discovery = "${var.dcos_master_discovery}"
    dcos_master_dns_bindall = "${var.dcos_master_dns_bindall}"
    # TODO(bernadinm) Terraform Bug: 9488.  Templates will not accept list, but only strings.
    # Workaround is to flatten the list as a string below. Fix when this is closed.
    dcos_master_list = "\n - ${join("\n - ", azurerm_network_interface.master_nic.*.private_ip_address)}"
    dcos_no_proxy = "${var.dcos_no_proxy}"
    dcos_num_masters = "${var.num_of_masters}"
    dcos_oauth_enabled = "${var.dcos_oauth_enabled}"
    dcos_overlay_config_attempts = "${var.dcos_overlay_config_attempts}"
    dcos_overlay_enable = "${var.dcos_overlay_enable}"
    dcos_overlay_mtu = "${var.dcos_overlay_mtu}"
    dcos_overlay_network = "${var.dcos_overlay_network}"
    dcos_process_timeout = "${var.dcos_process_timeout}"
    dcos_previous_version = "${var.dcos_previous_version}"
    dcos_agent_list = "\n - ${join("\n - ", azurerm_network_interface.agent_nic.*.private_ip_address)}"
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
    cluster_instance_ids = "${azurerm_virtual_machine.bootstrap.id}"
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
    dcos_exhibitor_address = "${azurerm_lb.master_internal_load_balancer.private_ip_address}"
    dcos_exhibitor_azure_account_key = "${coalesce(var.dcos_exhibitor_azure_account_key, azurerm_storage_account.dcos-exhibitor-account.primary_access_key)}"
    dcos_exhibitor_azure_account_name = "${coalesce(var.dcos_exhibitor_azure_account_name, azurerm_storage_account.dcos-exhibitor-account.name)}"
    dcos_exhibitor_azure_prefix = "${coalesce(var.dcos_exhibitor_azure_prefix, data.template_file.cluster-name.rendered)}"
    dcos_exhibitor_explicit_keys = "${var.dcos_exhibitor_explicit_keys}"
    dcos_exhibitor_storage_backend = "${var.dcos_exhibitor_storage_backend}"
    dcos_exhibitor_zk_hosts = "${var.dcos_exhibitor_zk_hosts}"
    dcos_exhibitor_zk_path = "${var.dcos_exhibitor_zk_path}"
    dcos_gc_delay = "${var.dcos_gc_delay}"
    dcos_http_proxy = "${var.dcos_http_proxy}"
    dcos_https_proxy = "${var.dcos_https_proxy}"
    dcos_log_directory = "${var.dcos_log_directory}"
    dcos_master_external_loadbalancer = "${coalesce(var.dcos_master_external_loadbalancer, azurerm_public_ip.master_load_balancer_public_ip.fqdn)}"
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
    host = "${element(azurerm_public_ip.bootstrap_public_ip.*.fqdn, 0)}"
    user = "${coalesce(var.azure_admin_username, module.azure-tested-oses.user)}"
    private_key = "${local.private_key}"
    agent = "${local.agent}"
  }

  # DCOS ip detect script
  provisioner "file" {
   source = "${var.ip-detect["azure"]}"
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

output "bootstrap_host_public_ip" {
  value = "${azurerm_public_ip.bootstrap_public_ip.fqdn}"
}
