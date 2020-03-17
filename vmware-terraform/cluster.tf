#######################
# Cluster declaration #
#######################

provider "vsphere" {
  user           = var.vsphere_user
  password       = var.vsphere_password
  vsphere_server = var.vsphere_server

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = var.vsphere_datacenter
}

data "vsphere_datastore" "datastore" {
  name          = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_resource_pool" "pool" {
  name          = var.vsphere_resource_pool
  datacenter_id = data.vsphere_datacenter.dc.id
}

##############################
# Configure the DNS Provider #
##############################

provider "dns" {
  update {
#    server        = "172.16.250.2"
    server        = "10.110.0.1"
  }
}

##############
# Networking #
##############

data "vsphere_network" "network" {
  name          = var.vsphere_network
  datacenter_id = data.vsphere_datacenter.dc.id
}


################
# Registration #
################
#data "template_file" "register_scc" {
#  template = file("cloud-init/register-scc.tpl")
#  count    = var.caasp_registry_code == "" ? 0 : 1
#  vars = {
#    sle_registry_code   = var.sle_registry_code
#    caasp_registry_code = var.caasp_registry_code
#  }
#}


#####################
### Cluster admin   #
#####################

#data "template_file" "zypper_repositories" {
#  template = file("cloud-init/repository.tpl")
#  count    = length(var.repositories)
  #  vars {
  #    repository_url  = "${element(values(var.repositories[count.index]), 0)}"
  #    repository_name = "${element(keys(var.repositories[count.index]), 0)}"
  #  }
#}

resource "libvirt_volume" "admin" {
  name           = "${var.name_prefix}admin.qcow2"
  pool           = var.pool
  size           = var.disk_size
  base_volume_id = libvirt_volume.img.id
#  count          = 1
}

data "template_file" "admin_cloud_init_user_data" {
  # needed when 0 admin nodes are defined
#  count    = var.admin_count
  template = file("cloud-init/admin.cfg.tpl")

  vars = {
    fqdn            = "${var.name_prefix}admin.${var.name_prefix}${var.domain_name}"
    authorized_keys = join("\n", formatlist("  - %s", var.authorized_keys))
#repositories    = join("\n", data.template_file.zypper_repositories.*.rendered)
    repositories = ""
#    register_scc    = join("\n", data.template_file.register_scc.*.rendered)
    register_scc    = ""
#    packages        = join("\n", formatlist("  - %s", var.packages))
    packages        = ""
    username        = var.username
    password        = var.password
    rmt_server_url  = var.rmt_server_url
  }

}

resource "libvirt_cloudinit_disk" "admin" {
  # needed when 0 admin nodes are defined
#  count = var.admin_count
  name  = "${var.name_prefix}admin_cloud_init.iso"
  pool  = var.pool
  user_data = data.template_file.admin_cloud_init_user_data.rendered
  network_config = file("cloud-init/network.cfg")
}

resource "libvirt_domain" "admin" {
#  count      = var.admin_count
  name       = "${var.name_prefix}admin"
  memory     = var.admin_memory
  vcpu       = var.admin_vcpu
  cloudinit  = libvirt_cloudinit_disk.admin.id
  metadata   = "admin.${var.domain_name},admin,${var.name_prefix}"

#  provisioner "file" {
#    source      = "files/dot_all_nodes"
#    destination = "/home/sles/.all_nodes"
#  }

  # cpu {
  #   mode = "host-passthrough"
  # }

  disk {
    volume_id = libvirt_volume.admin.id
  }

  network_interface {
    network_id     = libvirt_network.network.id
    hostname       = "${var.name_prefix}admin"
    addresses      = [cidrhost(var.network, 256 + 10)]
    wait_for_lease = true
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
  }

  connection {
    type     = "ssh"
    user     = "root"
    password = "linux"
  }
}

output "admin" {
  value = [libvirt_domain.admin.network_interface.0.addresses.0]
}
#####################
### Cluster masters #
#####################

#data "template_file" "zypper_repositories" {
#  template = file("cloud-init/repository.tpl")
#  count    = length(var.repositories)
  #  vars {
  #    repository_url  = "${element(values(var.repositories[count.index]), 0)}"
  #    repository_name = "${element(keys(var.repositories[count.index]), 0)}"
  #  }
#}

resource "libvirt_volume" "master" {
  name           = "${var.name_prefix}master_${count.index}.qcow2"
  pool           = var.pool
  size           = var.disk_size
  base_volume_id = libvirt_volume.img.id
  count          = var.master_count
}

data "template_file" "master_cloud_init_user_data" {
  # needed when 0 master nodes are defined
  count    = var.master_count
  template = file("cloud-init/master.cfg.tpl")

  vars = {
    fqdn            = "${var.name_prefix}master-${count.index}.${var.name_prefix}${var.domain_name}"
    authorized_keys = join("\n", formatlist("  - %s", var.authorized_keys))
#repositories    = join("\n", data.template_file.zypper_repositories.*.rendered)
    repositories = ""
#    register_scc    = join("\n", data.template_file.register_scc.*.rendered)
    register_scc    = ""
#    packages        = join("\n", formatlist("  - %s", var.packages))
    packages        = ""
    username        = var.username
    password        = var.password
    rmt_server_url  = var.rmt_server_url
  }

#  depends_on = [libvirt_domain.admin]
}

resource "libvirt_cloudinit_disk" "master" {
  # needed when 0 master nodes are defined
  count = var.master_count
  name  = "${var.name_prefix}master_cloud_init_${count.index}.iso"
  pool  = var.pool
  user_data = element(
    data.template_file.master_cloud_init_user_data.*.rendered,
    count.index,
  )
  network_config = file("cloud-init/network.cfg")
}

resource "libvirt_domain" "master" {
  count      = var.master_count
  name       = "${var.name_prefix}master-${count.index}"
  memory     = var.master_memory
  vcpu       = var.master_vcpu
  cloudinit  = element(libvirt_cloudinit_disk.master.*.id, count.index)
  metadata   = "master-${count.index}.${var.domain_name},master,${count.index},${var.name_prefix}"
#  depends_on = [libvirt_domain.admin]

  # cpu {
  #   mode = "host-passthrough"
  # }

  disk {
    volume_id = element(libvirt_volume.master.*.id, count.index)
  }

  network_interface {
    network_id     = libvirt_network.network.id
    hostname       = "${var.name_prefix}master-${count.index}"
    addresses      = [cidrhost(var.network, 512 + count.index)]
    wait_for_lease = true
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
  }

  connection {
    type     = "ssh"
    user     = "root"
    password = "linux"
  }
}

output "masters" {
  value = [libvirt_domain.master.*.network_interface.0.addresses.0]
}

####################
## Cluster workers #
####################

resource "libvirt_volume" "worker" {
  name           = "${var.name_prefix}worker_${count.index}.qcow2"
  pool           = var.pool
  size           = var.disk_size
  base_volume_id = libvirt_volume.img.id
  count          = var.worker_count
}

data "template_file" "worker_cloud_init_user_data" {
  # needed when 0 worker nodes are defined
  count    = var.worker_count
  template = file("cloud-init/worker.cfg.tpl")

  vars = {
    fqdn            = "${var.name_prefix}worker-${count.index}.${var.name_prefix}${var.domain_name}"
    authorized_keys = join("\n", formatlist("  - %s", var.authorized_keys))
#    repositories    = join("\n", data.template_file.zypper_repositories.*.rendered)
    repositories = ""
#    register_scc    = join("\n", data.template_file.register_scc.*.rendered)
    register_scc    = ""
#    packages        = join("\n", formatlist("  - %s", var.packages))
    packages        = ""
    username        = var.username
    password        = var.password
    rmt_server_url  = var.rmt_server_url
  }

#  depends_on = [libvirt_domain.admin]
}

resource "libvirt_cloudinit_disk" "worker" {
  # needed when 0 worker nodes are defined
  count = var.worker_count
  name  = "${var.name_prefix}worker_cloud_init_${count.index}.iso"
  pool  = var.pool
  user_data = element(
    data.template_file.worker_cloud_init_user_data.*.rendered,
    count.index,
  )
  network_config = file("cloud-init/network.cfg")
}

resource "libvirt_domain" "worker" {
  count      = var.worker_count
  name       = "${var.name_prefix}worker-${count.index}"
  memory     = var.worker_memory
  vcpu       = var.worker_vcpu
  cloudinit  = element(libvirt_cloudinit_disk.worker.*.id, count.index)
  metadata   = "worker-${count.index}.${var.domain_name},worker,${count.index},${var.name_prefix}"
#  depends_on = [libvirt_domain.admin]

  # cpu {
  #   mode = "host-passthrough"
  # }

  disk {
    volume_id = element(libvirt_volume.worker.*.id, count.index)
  }

  network_interface {
    network_id     = libvirt_network.network.id
    hostname       = "${var.name_prefix}worker-${count.index}"
    addresses      = [cidrhost(var.network, 768 + count.index)]
    wait_for_lease = true
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
  }

  connection {
    type     = "ssh"
    user     = "root"
    password = "linux"
  }
}

output "workers" {
  value = [libvirt_domain.worker.*.network_interface.0.addresses.0]
}

###########################
### Global Cluster worker #
###########################

#data "template_file" "zypper_repositories" {
#  template = file("cloud-init/repository.tpl")
#  count    = length(var.repositories)
  #  vars {
  #    repository_url  = "${element(values(var.repositories[count.index]), 0)}"
  #    repository_name = "${element(keys(var.repositories[count.index]), 0)}"
  #  }
#}

resource "libvirt_volume" "global_worker" {
  name           = "${var.name_prefix}global_worker.qcow2"
  pool           = var.pool
  size           = var.disk_size
  base_volume_id = libvirt_volume.img.id
#  count          = 1
}

data "template_file" "global_worker_cloud_init_user_data" {
  # needed when 0 global_worker nodes are defined
#  count    = var.global_worker_count
  template = file("global-cluster-cloud-init/global_worker.cfg.tpl")

  vars = {
#    fqdn            = "${var.name_prefix}global_worker.${var.name_prefix}${var.domain_name}"
    fqdn            = "${var.name_prefix}global_worker${var.libvirt_host_number}.${var.name_prefix}${var.domain_name}"
    authorized_keys = join("\n", formatlist("  - %s", var.authorized_keys))
#repositories    = join("\n", data.template_file.zypper_repositories.*.rendered)
    repositories = ""
#    register_scc    = join("\n", data.template_file.register_scc.*.rendered)
    register_scc    = ""
#    packages        = join("\n", formatlist("  - %s", var.packages))
    packages        = ""
    username        = var.username
    password        = var.password
    rmt_server_url  = var.rmt_server_url
  }

}

resource "libvirt_cloudinit_disk" "global_worker" {
  # needed when 0 global_worker nodes are defined
#  count = var.global_worker_count
  name  = "${var.name_prefix}global_worker_cloud_init.iso"
  pool  = var.pool
  user_data = data.template_file.global_worker_cloud_init_user_data.rendered
  network_config = file("global-cluster-cloud-init/network-${var.libvirt_host_number}.cfg")
}

resource "libvirt_domain" "global_worker" {
  name       = "${var.name_prefix}global_worker${var.libvirt_host_number}"
  memory     = var.global_worker_memory
  vcpu       = var.global_worker_vcpu
  cloudinit  = libvirt_cloudinit_disk.global_worker.id
  metadata   = "global_worker.${var.domain_name},global_worker,${var.name_prefix}"

#  provisioner "file" {
#    source      = "files/dot_all_nodes"
#    destination = "/home/sles/.all_nodes"
#  }

  # cpu {
  #   mode = "host-passthrough"
  # }

  disk {
    volume_id = libvirt_volume.global_worker.id
  }

  network_interface {
    bridge = var.lan_bridge
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
  }

  connection {
    type     = "ssh"
    user     = "root"
    password = "linux"
  }
}

#output "admin" {
#  value = [libvirt_domain.admin.network_interface.0.addresses.0]
#}
#output "global_worker" {
#  value = [libvirt_domain.global_worker.network_interface.0.addresses.0]
#}
