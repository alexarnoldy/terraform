#####################
# vmware  variables #
#####################

variable "vsphere_datacenter" {
  default     = "IHV-Lab"
  description = "Datacenter to deploy cluster in. Must be preconfigured"
}

variable "stack_name" {
  default     = "caasp-testing"
  description = "Will prefix names of most created objects"
}

variable "vsphere_resource_pool" {
  default     = "hackweek_2020_rp"
  description = "Datacenter to deploy cluster in. Must be preconfigured"
}

variable "template_name" {
  default     = "CaaSP-Node-Template"
  description = "Base image for cluster nodes. Must be preconfigured"
}

variable "vsphere_datastore" {
  default     = "datastore1"
  description = "Datastore that will hold all cluster nodes. Must be preconfigured"
}

variable "vsphere_network" {
  default     = "VM Network"
  description = "Network to deploy cluster on. Must be preconfigured"
}

variable "firmware" {
  default     = "bios"
  description = "Firmware interface to use"
}

variable "guest_id" {
  default     = "sles12_64Guest"
  description = "Guest ID of the virtual machine"
}

#####################
# CaaSP variables #
#####################

variable "caasp_registry_code" {
  default     = ""
  description = "SUSE CaaSP Product Registration Code"
}

variable "rmt_server_name" {
  default     = "http://rmt.hol1289.local"
  description = "SUSE Repository Mirroring Server Name"
}



#####################
# Cluster variables #
#####################

variable "rmt_server_url" {
  default     = "http://rmt.hol1289.local"
#  default     = "http://rmt.suse.hpc.local"
  description = "RMT server with http or https connection"
}

variable "repositories" {
#  type = string
  default = "https://download.opensuse.org/repositories/devel:/CaaSP:/Head:/ControllerNode/openSUSE_Leap_15.0"
#  default = [
#    {
#      caasp_devel_leap15 = "https://download.opensuse.org/repositories/devel:/CaaSP:/Head:/ControllerNode/openSUSE_Leap_15.0"
#    },
#  ]

  description = "Urls of the repositories to mount via cloud-init"
}


variable "admin_memory" {
  default     = 4096
  description = "The amount of RAM for the admin"
}

variable "admin_vcpu" {
  default     = 2
  description = "The amount of virtual CPUs for the admin"
}

variable "master_count" {
  default     = 1
  description = "Number of masters to be created"
}

variable "master_memory" {
  default     = 8192
  description = "The amount of RAM for a master"
}

variable "master_vcpu" {
  default     = 2
  description = "The amount of virtual CPUs for a master"
}

variable "worker_count" {
  default     = 2
  description = "Number of workers to be created"
}

variable "worker_memory" {
  default     = 16384
  description = "The amount of RAM for a worker"
}

variable "worker_vcpu" {
  default     = 8
  description = "The amount of virtual CPUs for a worker"
}

variable "global_worker_memory" {
## Set default to 1 to effectively disable the global workers
#  default     = 1
  default     = 12288
  description = "The amount of RAM for a worker"
}

variable "global_worker_vcpu" {
## Set default to 1 to effectively disable the global workers
#  default     = 1
  default     = 8
  description = "The amount of virtual CPUs for a worker"
}

variable "name_prefix" {
#  type        = string
  default     = "caasp-"
  description = "Optional prefix to be able to have multiple clusters on one host"
}

variable "domain_name" {
#  type        = string
  default     = "susecon.lab"
  description = "The domain name"
}

variable "lan_network" {
#  type        = string
  default     = "172.16.240.0/24"
  description = "Network used by the cluster"
}


variable "lan_net_base" {
  default     = "10.110.1.102"
  description = "First three octets of the network address"
}

variable "authorized_keys" {
#  type        = list(string)
  default     = ["ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDGkun2+5NDxqfy995qWNW4dkKZ3GsSGM0S1VG7etZ7KMI8rEZWLjIgQ0BX9ayEAjiY5gUtoaG7P9YO/+O2T+ZOc+A2O4RiRreLNQ9FoLJF0ekfbK6heVLVF1d9z1AHhEulORK8T2Ggn4BIxTv+DDint6ebs+W1DyhCc4o5jCk3mZM19c3N/2yhgfHkDVgrDaxTmrTOAkiZGd26D06X8VteiH3ys/4VtP2j7ZFDJ3Jzz8ySDzRIkJ8OP1KJvHi6uz7aZLh2fLJQsoZttuCWMO7kZGd6OaQn0EJ5FSMAmP6C8b8afybdcMZZ1DaOnKn1Tk6vLeO7uV5squZn3r4t6yAb admin@infra2", "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDUrbRE8QBHSHvty8Y4g/iFveUlIHTK4590NYN4txCBsup7xEednzcGISCfbI2LcvwGRtmeDnhJ3CyA4j2A83neWNKotD7SoYtYQzLP9RmDGfRL1+lLHebAOvTt4JxG1xL8ay5QdsXRMvmvBcLZtZVfICT776R98XUbN2OX3LDCYusg7TwleR1TBDAASzpEoy1bFxrO7Eu6x9fBhELjYigZAs/NMkNr/BTrbByxy8JwxyTWrY6aHbrAulVWUDnBQum07QF3UDqWlgAfeUMNDUf6HevGPmWWD+CVu0T6o7QUjP8h+bFmIT7SpoAekziPsfMF2xPh/PUqzR00g8g6Aoi7 sles@caasp-admin"]
  description = "ssh keys to inject into all the nodes"
}


variable "username" {
  default     = "sles"
  description = "Username for the cluster nodes"
}

variable "password" {
  default     = "linux"
  description = "Password for the cluster nodes"
}

# Extend disk size to 24G (JeOS-KVM default size) because we use
# JeOS-OpenStack instead of JeOS-KVM image with libvirt provider
variable "disk_size" {
  default     = "25769803776"
  description = "disk size (in bytes)"
}
