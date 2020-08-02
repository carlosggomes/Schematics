variable "ssh_key" {}
variable "resource_group" {}
variable "name" {}

# Define Provider, VPC Gen2 and Region
provider "ibm" {
  generation = 2
  region = "us-south"
}

locals {
  BASENAME = "${var.name}" 
  ZONE     = "us-south-1"
}

resource ibm_is_vpc "vpc" {
  name = "${local.BASENAME}-vpc"
}

resource ibm_is_security_group "sg1" {
  name = "${local.BASENAME}-sg1"
  vpc  = "${ibm_is_vpc.vpc.id}"
}

# allow all incoming network traffic on port 22
resource "ibm_is_security_group_rule" "ingress_ssh_all" {
  group     = "${ibm_is_security_group.sg1.id}"
  direction = "inbound"
  remote    = "0.0.0.0/0"                       

  tcp = {
    port_min = 22
    port_max = 22
  }
}

# Create subnet
resource ibm_is_subnet "subnet1" {
  name = "${local.BASENAME}-subnet1"
  vpc  = "${ibm_is_vpc.vpc.id}"
  zone = "${local.ZONE}"
  total_ipv4_address_count = 256
}

# Define VM Image Template
data ibm_is_image "ubuntu" {
  name = "ibm-ubuntu-16-04-5-minimal-amd64-1"
}

# Define SSH Key for use with VM
data ibm_is_ssh_key "ssh_key_id" {
  name = "${var.ssh_key}"
}

# Define Resource Group to be used
data ibm_resource_group "group" {
  name = "${var.resource_group}"
}

# Create VM in VPC
resource ibm_is_instance "vsi1" {
  name    = "${local.BASENAME}-vsi1"
  resource_group = "${data.ibm_resource_group.group.id}"
  vpc     = "${ibm_is_vpc.vpc.id}"
  zone    = "${local.ZONE}"
  keys    = ["${data.ibm_is_ssh_key.ssh_key_id.id}"]
  image   = "${data.ibm_is_image.ubuntu.id}"
  profile = "bx2-2x8"

  primary_network_interface = {
    subnet          = "${ibm_is_subnet.subnet1.id}"
    security_groups = ["${ibm_is_security_group.sg1.id}"]
  }
}

# Create Floating Floating IP to access the VM from Internet
resource ibm_is_floating_ip "fip1" {
  name   = "${local.BASENAME}-fip1"
  target = "${ibm_is_instance.vsi1.primary_network_interface.0.id}"
}

output sshcommand {
  value = "ssh root@${ibm_is_floating_ip.fip1.address}"
}

