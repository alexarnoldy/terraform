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
#packages:
#${packages}

write_files:
  - path: /home/sles/.all_nodes
    permissions: "0644"
    content: |
      caasp-master-0.caasp-susecon.lab
      caasp-worker-0.caasp-susecon.lab
      caasp-worker-1.caasp-susecon.lab
  - path: /home/sles/.ssh/config
    encoding: b64
    permissions: "0644"
    content: SE9TVCBjYWFzcC1sYi5jYWFzcC1zdXNlY29uLmxhYiBjYWFzcC1sYiBsYgogIEhPU1ROQU1FIGNhYXNwLWxiLmNhYXNwLXN1c2Vjb24ubGFiCkhPU1QgY2Fhc3AtbWFzdGVyLTAuY2Fhc3Atc3VzZWNvbi5sYWIgY2Fhc3AtbWFzdGVyLTAgbWFzdGVyLTAKICBIT1NUTkFNRSBjYWFzcC1tYXN0ZXItMC5jYWFzcC1zdXNlY29uLmxhYgpIT1NUIGNhYXNwLXdvcmtlci0wLmNhYXNwLXN1c2Vjb24ubGFiIGNhYXNwLXdvcmtlci0wIHdvcmtlci0wCiAgSE9TVE5BTUUgY2Fhc3Atd29ya2VyLTAuY2Fhc3Atc3VzZWNvbi5sYWIKSE9TVCBjYWFzcC13b3JrZXItMS5jYWFzcC1zdXNlY29uLmxhYiBjYWFzcC13b3JrZXItMSB3b3JrZXItMQogIEhPU1ROQU1FIGNhYXNwLXdvcmtlci0xLmNhYXNwLXN1c2Vjb24ubGFiIAoK
  - path: /home/sles/.ssh/id_rsa
    encoding: b64
    permissions: "0600"
    content: LS0tLS1CRUdJTiBPUEVOU1NIIFBSSVZBVEUgS0VZLS0tLS0KYjNCbGJuTnphQzFyWlhrdGRqRUFBQUFBQkc1dmJtVUFBQUFFYm05dVpRQUFBQUFBQUFBQkFBQUJGd0FBQUFkemMyZ3RjbgpOaEFBQUFBd0VBQVFBQUFRRUExSzIwUlBFQVIwaDc3Y3ZHT0lQNGhiM2xKU0IweXVPZmREV0RlTGNRZ2JMcWU4UkhuWjgzCkJpRWduMnlOaTNMOEJrYlpuZzU0U2R3c2dPSTlnUE41M2xqU3FMUSswcUdMV0VNeXovVVpneG4wUzlmcFN4M213RHIwN2UKQ2NSdGNTL0dzdVVIYkYwVEw1cndYQzJiV1ZYeUFrKysra2ZmRjFHemRqbDl5d3dtTHJJTzA4SlhrZFV3UXdBRXM2UktNdApXeGNhenV4THVzZlh3WVJDNDJJb0dRTFB6VEpEYS93VTYyd2NzY3ZDY01jazFxMk9taDI2d0xwVlZsQTV3VUxwdE8wQmQxCkE2bHBZQUgzbEREUTFIK2gzcnhqNWxsZy9nbGJ0RStxTzBGSXovSWZteFppRSswcWFBSHBNNGo3SHpCZHNUNGZ6MUtzMGQKTklQSU9nS0l1d0FBQThpOWpuZjd2WTUzK3dBQUFBZHpjMmd0Y25OaEFBQUJBUURVcmJSRThRQkhTSHZ0eThZNGcvaUZ2ZQpVbElIVEs0NTkwTllONHR4Q0JzdXA3eEVlZG56Y0dJU0NmYkkyTGN2d0dSdG1lRG5oSjNDeUE0ajJBODNuZVdOS290RDdTCm9ZdFlRekxQOVJtREdmUkwxK2xMSGViQU92VHQ0SnhHMXhMOGF5NVFkc1hSTXZtdkJjTFp0WlZmSUNUNzc2Ujk4WFViTjIKT1gzTERDWXVzZzdUd2xlUjFUQkRBQVN6cEVveTFiRnhyTzdFdTZ4OWZCaEVMallpZ1pBcy9OTWtOci9CVHJiQnl4eThKdwp4eVRXclk2YUhickF1bFZXVURuQlF1bTA3UUYzVURxV2xnQWZlVU1ORFVmNkhldkdQbVdXRCtDVnUwVDZvN1FValA4aCtiCkZtSVQ3U3BvQWVremlQc2ZNRjJ4UGgvUFVxelIwMGc4ZzZBb2k3QUFBQUF3RUFBUUFBQVFBdmlkaEdwTHdVTXU2SW04amwKN3hISkMwWkNBenczOGFNOXZZeHltakRWWE9HdTRwUERkc2c4MVlET1FkeHR0RGtEU2lqd2ZIbUV3UE10cCtScGc0TFZJWApPTkJDVWF2Y05BNmx4Y1FZUC9XdmpSVHlTMWhxeUNnV3NvRk5HNXYrOWRmck91aHEzMjhmYi9tVUVSbXRZVm1rREtFNm5vCkFPWFZQSTlGYmE0UTlOVWFJVkJzb3EwTms3aXFlVDY5Wk9LdFM2OHJsK0VBQ2RSTWF4SjU3M0loK2YzL2dBV01LUlltWGQKZ2VJSDQ2NDdlM0FseHhIYmJjNTJnWHltVGlvdjVtTG44dUNscU9CaTdjUUkzUXlKa0RiQlQ4NndHbGtkNG5pQjZWMzV0RgpjVFFNYnpyVmZ6YUFCL1czaHpGR2NjMUpTNGhaOXllQ1gwdkdUYVdVRjErSkFBQUFnUUN2TEU2MkZEODVXemxnQVVZSWttCnAreWw2S3RSNUI0c3pVV1JsNURkSjFCdm5yaVpFSGwxN1NwcVdpcVZRNFVUbFkxRFlSaHQ0NHBoUm1yK1Z2K0lwSHdRa3UKUU0rNXB2THZhTSsxV0lzRGVPNjNpNllBUnBUVkVSZjN4MVVGbWZDN2xKQ09pWVNHT0ViblE2djBDL3dEK0pMQTlXU0V2NQpsQWRCZnZQMUV4TWdBQUFJRUE2OVBrRStxRHpyZVcwU0xyZlNNNGtmeHlpUHh6eXdzMFk0MXo0RjhiME83dklwVVJNaVFzCjhRV2xyN05LOUJ4cjZpS1NNU0RLTlF1SXFCeElyaExFa3ZsTThuSEx0eWlQRkI0RmdVdXdidytzV1JIN1ByTTB6NnVoSkgKQ0JLNEN4ckxDTk1YTXcxNVFSVytHcFM4eFYwMDkxbk5HNUV3V1ZoTmhGNGpFUFBtY0FBQUNCQU9iZTViVDZ5VDB5Y0JNMQpvSlpGWjcxYlIvNUZWa0h6TExFSUZzUG9kclkwN1ZGeVFLNFYrYUtzMG40d3pnSEZYemg5S1l3a2xaa1BXSTlYQjh2RG15CnhEbjBRVjVvR1NIbVRGbThaWWN3LzJyTVh4VGY2UFZMTjNLUWdnVlpQQzF4NkwvOVQwZmx1TWpQZW1NRGNUWVJkMldmanEKZmRkMVpncnY5S1NYNjBhTkFBQUFFSE5zWlhOQVkyRmhjM0F0WVdSdGFXNEJBZz09Ci0tLS0tRU5EIE9QRU5TU0ggUFJJVkFURSBLRVktLS0tLQo=
  - path: /home/sles/.ssh/id_rsa.pub
    encoding: b64
    permissions: "0600"
    content: c3NoLXJzYSBBQUFBQjNOemFDMXljMkVBQUFBREFRQUJBQUFCQVFEVXJiUkU4UUJIU0h2dHk4WTRnL2lGdmVVbElIVEs0NTkwTllONHR4Q0JzdXA3eEVlZG56Y0dJU0NmYkkyTGN2d0dSdG1lRG5oSjNDeUE0ajJBODNuZVdOS290RDdTb1l0WVF6TFA5Um1ER2ZSTDErbExIZWJBT3ZUdDRKeEcxeEw4YXk1UWRzWFJNdm12QmNMWnRaVmZJQ1Q3NzZSOThYVWJOMk9YM0xEQ1l1c2c3VHdsZVIxVEJEQUFTenBFb3kxYkZ4ck83RXU2eDlmQmhFTGpZaWdaQXMvTk1rTnIvQlRyYkJ5eHk4Snd4eVRXclk2YUhickF1bFZXVURuQlF1bTA3UUYzVURxV2xnQWZlVU1ORFVmNkhldkdQbVdXRCtDVnUwVDZvN1FValA4aCtiRm1JVDdTcG9BZWt6aVBzZk1GMnhQaC9QVXF6UjAwZzhnNkFvaTcgc2xlc0BjYWFzcC1hZG1pbgo=
  - path: /tmp/deploy_caasp.sh
    encoding: gz+b64
    permissions: "0744"
    content: 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
  - path: /root/recover_deployment.sh
    encoding: b64
    permissions: "0744"
    content: IyEvYmluL2Jhc2gKIyMgUnVuIGFzIHJvb3QgaWYgdGhlIGNsb3VkIGluaXQgc2NyaXB0cyBkb2Vzbid0IGZpbmlzaCBjb3JyZWN0bHkKY2hvd24gLVIgc2xlczp1c2VycyAvaG9tZS9zbGVzCnN1ZG8gLUggLXUgc2xlcyBiYXNoIC90bXAvZGVwbG95X2NhYXNwLnNoCg==
  - path: /home/sles/.bashrc
    encoding: b64
    permissions: "0644"
    content: c2V0IC1vIHZpCmFsaWFzIGtnbj0ia3ViZWN0bCBnZXQgbm9kZXMgLW8gd2lkZSIKYWxpYXMga2dkPSJrdWJlY3RsIGdldCBkZXBsb3ltZW50cyAtbyB3aWRlIgphbGlhcyBrZ3A9Imt1YmVjdGwgZ2V0IHBvZHMgLW8gd2lkZSIKYWxpYXMga2dwYT0ia3ViZWN0bCBnZXQgcG9kcyAtbyB3aWRlIC0tYWxsLW5hbWVzcGFjZXMiCmFsaWFzIGtnPSJrdWJlY3RsIGdldCAiCmFsaWFzIGthZj0ia3ViZWN0bCBhcHBseSAtZiIKYWxpYXMgc2NzPSJza3ViYSBjbHVzdGVyIHN0YXR1cyIK
  - path: /etc/exports
    encoding: b64
    permissions: "0644"
    content: L3B1YmxpYyAxMC4xMTAuMC4wLzIyKHJ3LG5vX3Jvb3Rfc3F1YXNoKQo=
  - path: /etc/idmapd.conf
    encoding: b64
    permissions: "0644"
    content: W0dlbmVyYWxdCgpWZXJib3NpdHkgPSAwClBpcGVmcy1EaXJlY3RvcnkgPSAvdmFyL2xpYi9uZnMvcnBjX3BpcGVmcwpEb21haW4gPSBjYWFzcC1zdXNlY29uLmxhYgoKW01hcHBpbmddCgpOb2JvZHktVXNlciA9IG5vYm9keQpOb2JvZHktR3JvdXAgPSBub2JvZHkK

runcmd:
  # Since we are currently inside of the cloud-init systemd unit, trying to
  # start another service by either `enable --now` or `start` will create a
  # deadlock. Instead, we have to use the `--no-block-` flag.
#  - [ systemctl, enable, --now, --no-block, haproxy ]
${register_scc}
#  - [ zypper, in, --force-resolution, --no-confirm, --force, podman, kernel-default, cri-o, kubernetes-kubeadm,  kubernetes-client, skuba-update ]
#  - [ reboot ]
  - SUSEConnect --cleanup
  - SUSEConnect -d
  - SUSEConnect --url ${rmt_server_url}
#  - SUSEConnect --url http://rmt.suse.hpc.local
  - SUSEConnect -p sle-module-containers/15.1/x86_64
  - SUSEConnect -p caasp/4.0/x86_64 --url ${rmt_server_url}
#  - SUSEConnect -p caasp/4.0/x86_64 --url http://rmt.suse.hpc.local
  - zypper install --force-resolution --no-confirm --force kernel-default
  - mkdir /public
  - chmod 777 /public
#  - zypper --non-interactive install nfs-kernel-server w3m
  - systemctl --now --no-block enable nfs-server
  - systemctl --now --no-block enable registry
#  - zypper --non-interactive install -t pattern SUSE-CaaSP-Management
#  - zypper --non-interactive update
  - chown -R sles:users /home/sles
#  - sleep 180
#  - sudo -H -u sles bash /tmp/deploy_caasp.sh
#  - sleep 120
  - reboot

bootcmd:
  - ip link set dev eth0 mtu 1400

final_message: "The system is finally up, after $UPTIME seconds"
