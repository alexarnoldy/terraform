/* This is the admin-node VM that manages TF CaaSP deployments
*/
provider "libvirt" {
  uri = "qemu:///system"
}

resource "libvirt_volume" "img" {
  name   = "base-image"
  source = "/home/admin/caasp-terraform/SLES15-SP1-JeOS.x86_64-15.1-OpenStack-Cloud-GM.qcow2"
  format = "qcow2"
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

/*
################
# Registration #
################
data "template_file" "register_scc" {
  template = file("register-scc.tpl")
  count    = var.caasp_registry_code == "" ? 0 : 1
  vars = {
    sle_registry_code   = var.sle_registry_code
    caasp_registry_code = var.caasp_registry_code
  }
}
*/

variable "disk_size" {
  default     = "25769803776"
  description = "disk size (in bytes)"
}


### CaaSP Admin node

resource "libvirt_volume" "caasp-admin-node-volume" {
  name = "caasp-admin-node.qcow2"
  pool = "default"
  size = var.disk_size
  base_volume_id = libvirt_volume.img.id
}

data "template_file" "user_data" {
  template = "${file("${path.module}/cloud_init.cfg")}"
}

# Use CloudInit to add the instance
resource "libvirt_cloudinit_disk" "caasp-admin-node-init" {
  name = "caasp-admin-node-init.iso"
#  user_data      = "${data.template_file.user_data.rendered}"
  user_data      = data.template_file.user_data.rendered
}

# Define KVM domain to create
resource "libvirt_domain" "caasp-admin-node" {
  name = "caasp-admin-node"
  memory = "2048"
  vcpu   = 2

  network_interface {
    bridge = "virbr1"
#    mac = "AA:BB:CC:11:21:94"
#    network_id     = "${libvirt_network.network.id}"                     
#    network_name   = "br241"
#    hostname       = "caasp-admin-node"          
#    addresses      = ["10.110.0.10/22"]
  }

  disk {
#    volume_id = "${libvirt_volume.caasp-admin-node-volume.id}"
    volume_id = libvirt_volume.caasp-admin-node-volume.id
  }

#  cloudinit = "${libvirt_cloudinit_disk.caasp-admin-node-init.id}"
  cloudinit = libvirt_cloudinit_disk.caasp-admin-node-init.id

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
  value = [libvirt_domain.caasp-admin-node.network_interface.0.addresses]
#  value = [libvirt_domain.worker.*.network_interface.0.addresses.0]

}
