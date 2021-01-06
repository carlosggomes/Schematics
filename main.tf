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
  name = var.name
  resource_group = "RG-cguarany"
}

# resource "ibm_is_vpc_route" "route1" {
#   name        = "route1"
#   vpc         = ibm_is_vpc.vpc1.id
#   zone        = var.zone1
#   destination = "192.168.4.0/24"
#   next_hop    = "10.240.0.4"
#   depends_on  = [ibm_is_subnet.subnet1]
# }

resource "ibm_is_vpc_address_prefix" "addprefix1" {
  name = "addprefix1"
  zone = var.zone1
  vpc  = ibm_is_vpc.vpc1.id
  cidr = "10.120.0.0/24"
}

# data "ibm_is_instance" "ds_instance" {
#   name = "vsi_instance"
# }

resource "ibm_is_subnet" "subnet1" {
  name            = "subnet1"
  resource_group = "RG-cguarany"
  vpc             = ibm_is_vpc.vpc1.id
  zone            = var.zone1
  ipv4_cidr_block = "10.240.0.0/28"
}

resource "ibm_is_security_group" "sg1" {
  name = "sg1"
  resource_group = "RG-cguarany"
  vpc  = ibm_is_vpc.vpc1.id
}

# resource "ibm_is_ssh_key" "ssh_key_id" {
#   name       = var.ssh_key
# }

# Define SSH Key for use with VM
data ibm_is_ssh_key "ssh_key_id" {
  name = var.ssh_key
}

resource "ibm_is_instance" "instance1" {
  name    = "instance1"
  resource_group = "RG-cguarany"
  image   = var.image
  profile = var.profile

  primary_network_interface {
    subnet = ibm_is_subnet.subnet1.id
  }

  vpc       = ibm_is_vpc.vpc1.id
  zone      = var.zone1
  # keys      = [ibm_is_ssh_key.sshkey.id]
  keys      = data.ibm_is_ssh_key.ssh_key_id.id
  user_data = file("nginx.sh")
}

resource "ibm_is_floating_ip" "floatingip1" {
  name   = "fip1"
  resource_group = "RG-cguarany"
  target = ibm_is_instance.instance1.primary_network_interface[0].id
}

resource "ibm_is_security_group_network_interface_attachment" "sgnic1" {
  security_group    = ibm_is_security_group.sg1.id
  network_interface = ibm_is_instance.instance1.primary_network_interface[0].id
}

resource "ibm_is_security_group_rule" "sg1_tcp_rule" {
  depends_on = [ibm_is_floating_ip.floatingip1]
  group      = ibm_is_vpc.vpc1.default_security_group
  direction  = "inbound"
  remote     = "0.0.0.0/0"

  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "sg1_icmp_rule" {
  depends_on = [ibm_is_floating_ip.floatingip1]
  group      = ibm_is_vpc.vpc1.default_security_group
  direction  = "inbound"
  remote     = "0.0.0.0/0"

  icmp {
    code = 0
    type = 8
  }
}

resource "ibm_is_security_group_rule" "sg1_app_tcp_rule" {
  depends_on = [ibm_is_floating_ip.floatingip1]
  group      = ibm_is_vpc.vpc1.default_security_group
  direction  = "inbound"
  remote     = "0.0.0.0/0"

  tcp {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_volume" "vol1" {
  name    = "vol1"
  profile = "10iops-tier"
  zone    = var.zone1
}

resource "ibm_is_volume" "vol2" {
  name     = "vol2"
  profile  = "custom"
  zone     = var.zone1
  iops     = 1000
  capacity = 200
}

# resource "ibm_is_network_acl" "isExampleACL" {
#   name = "is-example-acl"
#   rules {
#     name        = "outbound"
#     action      = "allow"
#     source      = "0.0.0.0/0"
#     destination = "0.0.0.0/0"
#     direction   = "outbound"
#     tcp {
#       port_max        = 65535
#       port_min        = 1
#       source_port_max = 60000
#       source_port_min = 22
#     }
#   }
#   rules {
#     name        = "inbound"
#     action      = "allow"
#     source      = "0.0.0.0/0"
#     destination = "0.0.0.0/0"
#     direction   = "inbound"
#     tcp {
#       port_max        = 65535
#       port_min        = 1
#       source_port_max = 60000
#       source_port_min = 22
#     }
#   }
# }

# resource "ibm_is_subnet_network_acl_attachment" attach {
#   subnet      = ibm_is_subnet.subnet1.id
#   network_acl = ibm_is_network_acl.isExampleACL.id
# }

# resource "ibm_is_public_gateway" "publicgateway1" {
#   name = "gateway1"
#   vpc  = ibm_is_vpc.vpc1.id
#   zone = var.zone1
# }

# data "ibm_is_vpc" "vpc1" {
#   name = ibm_is_vpc.vpc1.name
# }
# data "ibm_is_lb" "test_lb" {
#   name = ibm_is_lb.lb1.name
# }
# data ibm_is_lb_profiles "test_lb_profiles" {
# }
# data "ibm_is_lbs" "test_lbs" {
# }

//custom route table for subnet 1
# resource "ibm_is_vpc_routing_table" "test_cr_route_table1" {
#   name = "test-cr-route-table1"
#   vpc  = ibm_is_vpc.vpc1.id
# }

// subnet 
# resource "ibm_is_subnet" "test_cr_subnet1" {
#   depends_on      = [ibm_is_vpc_routing_table.test_cr_route_table1]
#   name            = "test-cr-subnet1"
#   vpc             = data.ibm_is_vpc.vpc1.id
#   zone            = "eu-de-1"
#   ipv4_cidr_block = "10.240.10.0/24"
#   routing_table   = ibm_is_vpc_routing_table.test_cr_route_table1.routing_table
# }

# //custom route 
# resource "ibm_is_vpc_routing_table_route" "test_custom_route1" {
#   depends_on    = [ibm_is_subnet.test_cr_subnet1]
#   vpc           = ibm_is_vpc.vpc1.id
#   routing_table = ibm_is_vpc_routing_table.test_cr_route_table1.routing_table
#   zone          = "eu-de-1"
#   name          = "custom-route-1"
#   next_hop      = ibm_is_instance.instance2.primary_network_interface[0].primary_ipv4_address
#   action        = "deliver"
#   destination   = ibm_is_subnet.test_cr_subnet1.ipv4_cidr_block
# }

# // data source for vpc default routing table
# data "ibm_is_vpc_default_routing_table" "default_table_test" {
#   vpc = ibm_is_vpc.vpc1.id
# }

# // data source for vpc routing tables
# data "ibm_is_vpc_routing_tables" "tables_test" {
#   vpc = ibm_is_vpc.vpc1.id
# }

# // data source for vpc routing table routes
# data "ibm_is_vpc_routing_table_routes" "routes_test" {
#   vpc           = ibm_is_vpc.vpc1.id
#   routing_table = ibm_is_vpc_routing_table.test_cr_route_table1.routing_table
# }

# resource "ibm_is_virtual_endpoint_gateway" "endpoint_gateway1" {
#   name = "my-endpoint-gateway-1"
#   target {
#     name          = "ibm-dns-server2"
#     resource_type = "provider_infrastructure_service"
#   }
#   vpc            = ibm_is_vpc.testacc_vpc.id
#   resource_group = data.ibm_resource_group.test_acc.id
# }

# resource "ibm_is_virtual_endpoint_gateway" "endpoint_gateway2" {
#   name = "my-endpoint-gateway-1"
#   target {
#     name          = "ibm-dns-server2"
#     resource_type = "provider_infrastructure_service"
#   }
#   vpc = ibm_is_vpc.testacc_vpc.id
#   ips {
#     subnet = ibm_is_subnet.testacc_subnet.id
#     name      = "test-reserved-ip1"
#   }
#   resource_group = data.ibm_resource_group.test_acc.id
# }

# resource "ibm_is_virtual_endpoint_gateway" "endpoint_gateway3" {
#   name = "my-endpoint-gateway-1"
#   target {
#     name          = "ibm-dns-server2"
#     resource_type = "provider_infrastructure_service"
#   }
#   vpc = ibm_is_vpc.testacc_vpc.id
#   ips {
#     id = "0737-5ab3c18e-6f6c-4a69-8f48-20e3456647b5"
#   }
#   resource_group = data.ibm_resource_group.test_acc.id
# }

# resource "ibm_is_virtual_endpoint_gateway_ip" "virtual_endpoint_gateway_ip" {
#   gateway    = ibm_is_virtual_endpoint_gateway.endpoint_gateway.id
#   reserved_ip = "0674-5ab3c18e-6f6c-4a69-8f48-20e3456647b5"
# }

# data "ibm_is_virtual_endpoint_gateway" "data_virtual_endpoint_gateway" {
#   name = ibm_is_virtual_endpoint_gateway.endpoint_gateway.name
# }

# data "ibm_is_virtual_endpoint_gateways" "data_virtual_endpoint_gateways" {

# }

# data "ibm_is_virtual_endpoint_gateway_ips" "data_virtual_endpoint_gateway_ips" {
#   gateway = ibm_is_virtual_endpoint_gateway.endpoint_gateway.id
# }

# output sshcommand {
#   value = ssh root@$ibm_is_floating_ip.fip1.address
# }