#cloud-config

# set locale
locale: en_US.UTF-8

# set timezone
timezone: America/Denver

# Set FQDN
fqdn: ${fqdn}

# set root password
chpasswd:
  list: |
    root:linux
    ${username}:${password}
  expire: False

ssh_authorized_keys:
${authorized_keys}

# need to disable gpg checks because the cloud image has an untrusted repo
zypper:
  repos:
${repositories}
  config:
    gpgcheck: "off"
    solver.onlyRequires: "true"
    download.use_deltarpm: "true"

# need to remove the standard docker packages that are pre-installed on the
# cloud image because they conflict with the kubic- ones that are pulled by
# the kubernetes packages
packages:
${packages}

bootcmd:
#  - ip link set dev eth0 mtu 1400
#  - ip addr add 172.16.240.240/24 dev eth0
#  - ip route add default via 172.16.240.1 dev eth0
#  - echo search caasp-terraformsusecon-hol.lab >> /etc/resolv.conf
#  - echo nameserver 172.16.250.2 >> /etc/resolv.conf

runcmd:
  # Since we are currently inside of the cloud-init systemd unit, trying to
  # start another service by either `enable --now` or `start` will create a
  # deadlock. Instead, we have to use the `--no-block-` flag.
  - [ systemctl, enable, --now, --no-block, haproxy ]
#${register_scc}
#  - [ zypper, in, --force-resolution, --no-confirm, --force, podman, kernel-default, cri-o, kubernetes-kubeadm,  kubernetes-client, skuba-update ]
#  - [ reboot ]
#  - SUSEConnect --url ${rmt_server_url}
##  - SUSEConnect --url http://rmt.suse.hpc.local
#  - SUSEConnect -p sle-module-containers/15.1/x86_64
#  - SUSEConnect -p caasp/4.0/x86_64 --url ${rmt_server_url}
##  - SUSEConnect -p caasp/4.0/x86_64 --url http://rmt.suse.hpc.local
#  - zypper --non-interactive install nfs-client
#  - zypper --non-interactive update
#  - reboot


final_message: "The system is finally up, after $UPTIME seconds"
