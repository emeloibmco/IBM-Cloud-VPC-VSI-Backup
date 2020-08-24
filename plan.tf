provider "ibm" {
  generation         = 1
  region             = "us-south"
}

data "ibm_resource_group" "group" {
  name = "${var.resource_group}"
}

resource "ibm_is_ssh_key" "sshkey" {
  name       = "keysshdemovpn"
  public_key = "${var.ssh_public}"
}

resource "ibm_is_vpc" "vpcbackup" {
  name = "vpcbackupdemo"
  resource_group = "${data.ibm_resource_group.group.id}"
}

resource "ibm_is_subnet" "subnetforvpn" {
  name            = "subnetforvpn"
  vpc             = "${ibm_is_vpc.vpcbackup.id}"
  zone            = "us-south-1"
  ipv4_cidr_block = "10.240.0.0/24"
  network_acl     = "${ibm_is_network_acl.acldemovpn.id}"
}

resource "ibm_is_vpn_gateway" "testacc_vpn_gateway" {
  name   = "vpnforvpcdemo"
  subnet = "${ibm_is_subnet.subnetforvpn.id}"
}

resource "ibm_is_security_group" "securitygroupdemovpn" {
  name = "securitygroupdemovpn"
  vpc  = "${ibm_is_vpc.vpcbackup.id}"
  resource_group = "${data.ibm_resource_group.group.id}"
}


resource "ibm_is_instance" "vsiwindows" {
  name    = "virtualservertest"
  image   = "9de244af-e231-4aae-a958-aa60d735c826"
  profile = "bx2-8x32"
  resource_group = "${data.ibm_resource_group.group.id}"


  primary_network_interface {
    subnet = "${ibm_is_subnet.subnetforvpn.id}"
    security_groups = ["${ibm_is_security_group.securitygroupdemovpn.id}"]
  }

  vpc       = "${ibm_is_vpc.vpcbackup.id}"
  zone      = "us-south-1"
  keys = ["${ibm_is_ssh_key.sshkey.id}"]
}

resource "ibm_is_instance" "vsilinux" {
  name    = "virtualservertest"
  image   = "7eb4e35b-4257-56f8-d7da-326d85452591"
  profile = "b-2x8"
  resource_group = "${data.ibm_resource_group.group.id}"


  primary_network_interface {
    subnet = "${ibm_is_subnet.subnetforvpn.id}"
    security_groups = ["${ibm_is_security_group.securitygroupdemovpn.id}"]
  }

  vpc       = "${ibm_is_vpc.vpcbackup.id}"
  zone      = "us-south-1"
  keys = ["${ibm_is_ssh_key.sshkey.id}"]
}

resource "ibm_is_security_group_rule" "testacc_security_group_rule_all" {
  group     = "${ibm_is_security_group.securitygroupdemovpn.id}"
  direction = "inbound"
  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "testacc_security_group_rule_icmp" {
  group     = "${ibm_is_security_group.securitygroupdemovpn.id}"
  direction = "inbound"
  icmp {
    type = 8
  }
}

resource "ibm_is_security_group_rule" "testacc_security_group_rule_out" {
  group     = "${ibm_is_security_group.securitygroupdemovpn.id}"
  direction = "outbound"
}
