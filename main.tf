# Define Provider, VPC Gen2 and Region
provider "ibm" {
  generation = 2
  region = "eu-de"
}

locals {
  BASENAME = var.name
  ZONE     = "eu-de-1"
}

# Cria VPC
resource "ibm_is_vpc" "vpc1" {
  name = format ("vpc-, %s", var.name)
  resource_group = "5598fcfd528744c9be5824a99742f0a4"
}

resource "ibm_is_security_group" "sg1" {
  name = "sg1"
  resource_group = "5598fcfd528744c9be5824a99742f0a4"
  vpc  = ibm_is_vpc.vpc1.id
}

resource "ibm_is_security_group_rule" "sg1_tcp_rule" {
  # depends_on = [ibm_is_floating_ip.floatingip1]
  # group      = ibm_is_vpc.vpc1.default_security_group
  group      = ibm_is_security_group.sg1.id
  direction  = "inbound"
  remote     = "0.0.0.0/0"

  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "sg1_icmp_rule" {
  # depends_on = [ibm_is_floating_ip.floatingip1]
  # group      = ibm_is_vpc.vpc1.default_security_group
  group      = ibm_is_security_group.sg1.id
  direction  = "inbound"
  remote     = "0.0.0.0/0"

  icmp {
    code = 0
    type = 8
  }
}

resource "ibm_is_security_group_rule" "sg1_app_tcp_rule" {
  # depends_on = [ibm_is_floating_ip.floatingip1]
  # group      = ibm_is_vpc.vpc1.default_security_group
  group      = ibm_is_security_group.sg1.id
  direction  = "inbound"
  remote     = "0.0.0.0/0"

  tcp {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_subnet" "subnet1" {
  name            = "subnet1"
  resource_group = "5598fcfd528744c9be5824a99742f0a4"
  vpc             = ibm_is_vpc.vpc1.id
  zone            = var.zone1
  total_ipv4_address_count = 256
}

# Define SSH Key for use with VM
data ibm_is_ssh_key "ssh_key_id" {
  name = var.ssh_key
}

resource "ibm_is_instance" "instance1" {
  name    = "instance1"
  resource_group = "5598fcfd528744c9be5824a99742f0a4"
  image   = var.image
  profile = var.profile

  primary_network_interface {
    subnet = ibm_is_subnet.subnet1.id
  }

  vpc       = ibm_is_vpc.vpc1.id
  zone      = var.zone1
  keys      = [data.ibm_is_ssh_key.ssh_key_id.id]
  user_data = file("nginx.sh")
}

resource "ibm_is_floating_ip" "floatingip1" {
  name   = "fip1"
  resource_group = "5598fcfd528744c9be5824a99742f0a4"
  target = ibm_is_instance.instance1.primary_network_interface[0].id
}

resource "ibm_is_security_group_network_interface_attachment" "sgnic1" {
  security_group    = ibm_is_security_group.sg1.id
  network_interface = ibm_is_instance.instance1.primary_network_interface[0].id
}



resource "ibm_is_volume" "vol1" {
  name    = "vol1"
  resource_group = "5598fcfd528744c9be5824a99742f0a4"
  profile = "10iops-tier"
  zone    = var.zone1
}

resource "ibm_is_volume" "vol2" {
  name     = "vol2"
  resource_group = "5598fcfd528744c9be5824a99742f0a4"
  profile  = "custom"
  zone     = var.zone1
  iops     = 1000
  capacity = 200
}