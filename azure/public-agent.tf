# Public Agent
resource "azurerm_managed_disk" "public_agent_managed_disk" {
  count                = "${var.num_of_public_agents}"
  name                 = "${data.template_file.cluster-name.rendered}-public-agent-${count.index + 1}"
  location             = "${var.azure_region}"
  resource_group_name  = "${azurerm_resource_group.dcos.name}"
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "${var.instance_disk_size}"
}

# mbernadin: Public Agent Load Balancer Settings for Public and Private

# Public IP addresses for the Public Front End load Balancer
resource "azurerm_public_ip" "public_agent_load_balancer_public_ip" {
  name                         = "${data.template_file.cluster-name.rendered}-public-lb-ip"
  location                     = "${var.azure_region}"
  resource_group_name          = "${azurerm_resource_group.dcos.name}"
  public_ip_address_allocation = "dynamic"
  domain_name_label = "public-agent-${data.template_file.cluster-name.rendered}"

  tags {
   Name       = "${coalesce(var.owner, data.external.whoami.result["owner"])}"
   expiration = "${var.expiration}"
  }
}


# Public IP addresses for the Public Front End load Balancer
resource "azurerm_public_ip" "public_agent_public_ip" {
  count                        = "${var.num_of_public_agents}"
  name                         = "${data.template_file.cluster-name.rendered}-public-agent-pub-ip-${count.index + 1}"
  location                     = "${var.azure_region}"
  resource_group_name          = "${azurerm_resource_group.dcos.name}"
  public_ip_address_allocation = "dynamic"
  domain_name_label = "${data.template_file.cluster-name.rendered}-public-agent-${count.index + 1}"

  tags {
   Name       = "${coalesce(var.owner, data.external.whoami.result["owner"])}"
   expiration = "${var.expiration}"
  }
}

# Front End Load Balancer
resource "azurerm_lb" "public_agent_public_load_balancer" {
  name                = "${data.template_file.cluster-name.rendered}-pub-agent-elb"
  location            = "${var.azure_region}"
  resource_group_name = "${azurerm_resource_group.dcos.name}"

  frontend_ip_configuration {
    name                 = "${data.template_file.cluster-name.rendered}-public-agent-ip-config"
    public_ip_address_id = "${azurerm_public_ip.public_agent_load_balancer_public_ip.id}"
  }

  tags {
   Name       = "${coalesce(var.owner, data.external.whoami.result["owner"])}"
   expiration = "${var.expiration}"
  }
}

# Back End Address Pool for Public and Private Loadbalancers
resource "azurerm_lb_backend_address_pool" "external_public_agent_backend_pool" {
  name                = "${data.template_file.cluster-name.rendered}-public_backend_address_pool"
  resource_group_name = "${azurerm_resource_group.dcos.name}"
  loadbalancer_id     = "${azurerm_lb.public_agent_public_load_balancer.id}"
}

# Load Balancer Rule
resource "azurerm_lb_rule" "agent_public_load_balancer_http_rule" {
  resource_group_name            = "${azurerm_resource_group.dcos.name}"
  loadbalancer_id                = "${azurerm_lb.public_agent_public_load_balancer.id}"
  name                           = "HTTPRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "${data.template_file.cluster-name.rendered}-public-agent-ip-config"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.external_public_agent_backend_pool.id}"
  probe_id                       = "${azurerm_lb_probe.agent_load_balancer_http_probe.id}"
  depends_on                     = ["azurerm_lb_probe.agent_load_balancer_http_probe"]
}

# Load Balancer Rule
resource "azurerm_lb_rule" "agent_public_load_balancer_https_rule" {
  resource_group_name            = "${azurerm_resource_group.dcos.name}"
  loadbalancer_id                = "${azurerm_lb.public_agent_public_load_balancer.id}"
  name                           = "HTTPSRule"
  protocol                       = "Tcp"
  frontend_port                  = 443
  backend_port                   = 443
  frontend_ip_configuration_name = "${data.template_file.cluster-name.rendered}-public-agent-ip-config"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.external_public_agent_backend_pool.id}"
  probe_id                       = "${azurerm_lb_probe.agent_load_balancer_https_probe.id}"
  depends_on                     = ["azurerm_lb_probe.agent_load_balancer_https_probe"]
}

#LB Probe - Checks to see which VMs are healthy and available
resource "azurerm_lb_probe" "agent_load_balancer_http_probe" {
  resource_group_name = "${azurerm_resource_group.dcos.name}"
  loadbalancer_id     = "${azurerm_lb.public_agent_public_load_balancer.id}"
  name                = "HTTP"
  port                = 80
}

#LB Probe - Checks to see which VMs are healthy and available
resource "azurerm_lb_probe" "agent_load_balancer_https_probe" {
  resource_group_name = "${azurerm_resource_group.dcos.name}"
  loadbalancer_id     = "${azurerm_lb.public_agent_public_load_balancer.id}"
  name                = "HTTPS"
  port                = 443
}


# Public Agent Security Groups for NICs
resource "azurerm_network_security_group" "public_agent_security_group" {
    name = "${data.template_file.cluster-name.rendered}-public-agent-security-group"
    location = "${var.azure_region}"
    resource_group_name = "${azurerm_resource_group.dcos.name}"

    tags {
      Name       = "${coalesce(var.owner, data.external.whoami.result["owner"])}"
      expiration = "${var.expiration}"
  }
}

resource "azurerm_network_security_rule" "public-agent-sshRule" {
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
    network_security_group_name = "${azurerm_network_security_group.public_agent_security_group.name}"
}


resource "azurerm_network_security_rule" "public-agent-httpRule" {
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
    network_security_group_name = "${azurerm_network_security_group.public_agent_security_group.name}"
}

resource "azurerm_network_security_rule" "public-agent-httpsRule" {
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
    network_security_group_name = "${azurerm_network_security_group.public_agent_security_group.name}"
}

resource "azurerm_network_security_rule" "public-agent-RangeOne" {
    name                        = "RangeOne"
    priority                    = 130
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "0-21"
    destination_port_range      = "0-21"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
    resource_group_name         = "${azurerm_resource_group.dcos.name}"
    network_security_group_name = "${azurerm_network_security_group.public_agent_security_group.name}"
}

resource "azurerm_network_security_rule" "public-agent-RangeTwo" {
    name                        = "RangeTwo"
    priority                    = 140
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "23-5050"
    destination_port_range      = "23-5050"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
    resource_group_name         = "${azurerm_resource_group.dcos.name}"
    network_security_group_name = "${azurerm_network_security_group.public_agent_security_group.name}"
}

resource "azurerm_network_security_rule" "public-agent-RangeThree" {
    name                        = "RangeThree"
    priority                    = 150
    direction                   = "Inbound"
    access                      = "Allow"
    protocol                    = "Tcp"
    source_port_range           = "5052-32000"
    destination_port_range      = "5052-32000"
    source_address_prefix       = "*"
    destination_address_prefix  = "*"
    resource_group_name         = "${azurerm_resource_group.dcos.name}"
    network_security_group_name = "${azurerm_network_security_group.public_agent_security_group.name}"
}

resource "azurerm_network_security_rule" "public-agent-internalEverything" {
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
    network_security_group_name = "${azurerm_network_security_group.public_agent_security_group.name}"
}

resource "azurerm_network_security_rule" "public-agent-everythingElseOutBound" {
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
    network_security_group_name = "${azurerm_network_security_group.public_agent_security_group.name}"
}
# End of Public Agent NIC Security Group

# Public Agent NICs with Security Group
resource "azurerm_network_interface" "public_agent_nic" {
  name                      = "${data.template_file.cluster-name.rendered}-public-agent-${count.index}-nic"
  location                  = "${var.azure_region}"
  resource_group_name       = "${azurerm_resource_group.dcos.name}"
  network_security_group_id = "${azurerm_network_security_group.public_agent_security_group.id}"
  count                     = "${var.num_of_public_agents}"

  ip_configuration {
   name                                    = "${data.template_file.cluster-name.rendered}-${count.index}-ipConfig"
   subnet_id                               = "${azurerm_subnet.public.id}"
   private_ip_address_allocation           = "dynamic"
   public_ip_address_id                    = "${element(azurerm_public_ip.public_agent_public_ip.*.id, count.index)}"
   load_balancer_backend_address_pools_ids = ["${azurerm_lb_backend_address_pool.external_public_agent_backend_pool.id}"]
  }

  tags {
   Name       = "${coalesce(var.owner, data.external.whoami.result["owner"])}"
   expiration = "${var.expiration}"
  }
}

# Create an availability set
resource "azurerm_availability_set" "public_agent_av_set" {
  name                         = "${data.template_file.cluster-name.rendered}-public-agent-avset"
  location                     = "${var.azure_region}"
  resource_group_name          = "${azurerm_resource_group.dcos.name}"
  platform_fault_domain_count  = 3
  platform_update_domain_count = 1
  managed                      = true
}

# Public Agent VM Coniguration
resource "azurerm_virtual_machine" "public-agent" {
    name                             = "${data.template_file.cluster-name.rendered}-public-agent-${count.index + 1}"
    location                         = "${var.azure_region}"
    resource_group_name              = "${azurerm_resource_group.dcos.name}"
    network_interface_ids            = ["${azurerm_network_interface.public_agent_nic.*.id[count.index]}"]
    availability_set_id              = "${azurerm_availability_set.public_agent_av_set.id}"
    vm_size                          = "${var.azure_public_agent_instance_type}"
    count                            = "${var.num_of_public_agents}"
    delete_os_disk_on_termination    = true
    delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "${module.azure-tested-oses.azure_publisher}"
    offer     = "${module.azure-tested-oses.azure_offer}"
    sku       = "${module.azure-tested-oses.azure_sku}"
    version   = "${module.azure-tested-oses.azure_version}"
  }

  storage_os_disk {
    name              = "os-disk-public-agent-${count.index + 1}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_data_disk {
    name            = "${azurerm_managed_disk.public_agent_managed_disk.*.name[count.index]}"
    managed_disk_id = "${azurerm_managed_disk.public_agent_managed_disk.*.id[count.index]}"
    create_option   = "Attach"
    lun             = 0
    disk_size_gb    = "${azurerm_managed_disk.public_agent_managed_disk.*.disk_size_gb[count.index]}"
  }

  os_profile {
    computer_name  = "public-agent-${count.index + 1}"
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
    host = "${element(azurerm_public_ip.public_agent_public_ip.*.fqdn, count.index)}"
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
    host = "${element(azurerm_public_ip.public_agent_public_ip.*.fqdn, count.index)}"
   }
 }

  tags {
   Name       = "${coalesce(var.owner, data.external.whoami.result["owner"])}"
   expiration = "${var.expiration}"
 }
}

# Create DCOS Mesos Public Agent Scripts to execute
module "dcos-mesos-agent-public" {
  source               = "github.com/bernadinm/tf_dcos_core"
  bootstrap_private_ip = "${azurerm_network_interface.bootstrap_nic.private_ip_address}"
  # Only allow upgrade and install as installation mode
  dcos_install_mode = "${var.state == "upgrade" ? "upgrade" : "install"}"
  dcos_version         = "${var.dcos_version}"
  role                 = "dcos-mesos-agent-public"
}

resource "null_resource" "public-agent" {
  # If state is set to none do not install DC/OS
  count = "${var.state == "none" ? 0 : var.num_of_public_agents}"
  # Changes to any instance of the cluster requires re-provisioning
  triggers {
    cluster_instance_ids = "${null_resource.bootstrap.id}"
    current_virtual_machine_id = "${azurerm_virtual_machine.public-agent.*.id[count.index]}"
  }
  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    host = "${element(azurerm_public_ip.public_agent_public_ip.*.fqdn, count.index)}"
    user = "${coalesce(var.azure_admin_username, module.azure-tested-oses.user)}"
  }

  count = "${var.num_of_public_agents}"

  # Generate and upload Public Agent script to node
  provisioner "file" {
    content     = "${module.dcos-mesos-agent-public.script}"
    destination = "run.sh"
  }

  # Wait for bootstrapnode to be ready
  provisioner "remote-exec" {
    inline = [
     "until $(curl --output /dev/null --silent --head --fail http://${azurerm_network_interface.bootstrap_nic.private_ip_address}/dcos_install.sh); do printf 'waiting for bootstrap node to serve...'; sleep 20; done"
    ]
  }

  # Install Public Agent Script
  provisioner "remote-exec" {
    inline = [
      "sudo chmod +x run.sh",
      "sudo ./run.sh",
    ]
  }
}
