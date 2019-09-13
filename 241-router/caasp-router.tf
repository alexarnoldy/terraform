/* This is the router VM that routes between the backend network (VLAN241) and
   the frontend network (VLAN240)
*/
provider "libvirt" {
  uri = "qemu:///system"
}

#provider "libvirt" {
#  alias = "infra1"
#  uri   = "qemu+ssh://root@172.16.240.101/system"
#}


### Host Networking

/* This is a simple way to create a NAT network but doesn't provide for name resolution
   to DHCP addressed hosts
resource "libvirt_network" "network" {
  name = "caasp-net"
  mode = "nat"
  domain = "caaspv4.net"
  addresses = ["10.0.0.0/22"]

# dns is defined but doesn't seem to work, at least in v0.5.2 of the libvirt provider
#dns = {
#  forwarders = {
#    address = "8.8.8.8"
#  }
#}
}
*/

/*
resource "libvirt_network" "network" {
  name = "br241"
  mode = "bridge"
  bridge = "br241"
#  domain = "caaspv4.net"
#  addresses = ["172.16.241.0/24"]
}
*/


### Router node

resource "libvirt_volume" "caasp-router-volume" {
  name = "caasp-router.qcow2"
  pool = "default"
  source = "../SLES15-SP1.x86_64-15.1-CloudImage-Updated.qcow2"
  format = "qcow2"
}

data "template_file" "user_data" {
  template = "${file("${path.module}/cloud_init.cfg")}"
}

# Use CloudInit to add the instance
resource "libvirt_cloudinit_disk" "caasp-router-init" {
  name = "caasp-router-init.iso"
  user_data      = "${data.template_file.user_data.rendered}"
}

# Define KVM domain to create
resource "libvirt_domain" "caasp-router" {
  name = "caasp-router"
  memory = "2048"
  vcpu   = 2

  network_interface {
    bridge = "br241"
#    mac = "AA:BB:CC:11:21:94"
#    network_id     = "${libvirt_network.network.id}"                     
#    network_name   = "br241"
#    hostname       = "caasp-router"          
    addresses      = ["172.16.241.254"]
  }

  disk {
    volume_id = "${libvirt_volume.caasp-router-volume.id}"
  }

  cloudinit = "${libvirt_cloudinit_disk.caasp-router-init.id}"

  console {
    type = "pty"
    target_type = "serial"
    target_port = "0"
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = true
  }
}

# Output Server IP
 output "ip" {
#  value = "${libvirt_domain.db1.network_interface.0.addresses.0}"
  value = "${libvirt_domain.caasp-router.network_interface.0.addresses}"
}
