provider "libvirt" {
  uri = "qemu:///system"
}

#provider "libvirt" {
#  alias = "server2"
#  uri   = "qemu+ssh://root@192.168.100.10/system"
#}


### Host Networking

# This is a simple way to create a NAT network but doesn't provide for name resolution
#  to DHCP addressed hosts
resource "libvirt_network" "network" {
  name = "caasp-net"
  mode = "nat"
  domain = "caaspv4.net"
  addresses = ["10.0.0.0/24"]

# dns is defined but doesn't seem to work, at least in v0.5.2 of the libvirt provider
#dns = {
#  forwarders = {
#    address = "8.8.8.8"
#  }
#}
}

/* This seems to want to create the bridge, which isn't what I want
resource "libvirt_network" "network" {
  name = "caasp-net"
  mode = "bridge"
  bridge = "br241"
  domain = "caaspv4.net"
  addresses = ["172.16.241.0/24"]
}
*/


### Master nodes

variable "master_count" {
  default = 1
}

resource "libvirt_volume" "master-volume" {
#  count = "3"
  count = "${var.master_count}"
  name = "caasp-node-${count.index + 1}.qcow2"
  pool = "default"
  source = "../SLES15-SP1.x86_64-15.1-CloudImage.qcow2"
  format = "qcow2"
}

data "template_file" "user_data" {
  template = "${file("${path.module}/cloud_init.cfg")}"
}

# Use CloudInit to add the instance
resource "libvirt_cloudinit_disk" "commoninit" {
  name = "commoninit.iso"
  user_data      = "${data.template_file.user_data.rendered}"
}

# Define KVM domain to create
resource "libvirt_domain" "instance" {
#  count = "3"
  count = "${var.master_count}"
  name = "caasp-node-${count.index + 1}"
  memory = "1024"
  vcpu   = 1

  network_interface {
    network_id     = "${libvirt_network.network.id}"                     
    hostname       = "master-${count.index}"          
    wait_for_lease = true
  }

  disk {
    volume_id = "${libvirt_volume.master-volume[count.index].id}"
  }

  cloudinit = "${libvirt_cloudinit_disk.commoninit.id}"

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

# Output Server IP - Isn't currently working
/*
output "ip" {
#  value = "${libvirt_domain.db1.network_interface.0.addresses.0}"
  value = "${libvirt_domain.master-${count.index}.network_interface.0.addresses}"
}
*/
