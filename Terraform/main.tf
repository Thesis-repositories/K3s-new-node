resource "proxmox_virtual_environment_vm" "k3s-worker" {
  name      = var.vm_hostname
  node_name = var.target_node

  agent {
    enabled = false
  }

  clone {
    vm_id = var.template_id
    full  = true
    node_name = var.template_node
  }

  disk {
    interface = "scsi0"
    size      = var.vm_disk_size
  }


  cpu {
    cores = var.vm_cpu_cores
  }

  memory {
    dedicated = var.vm_memory
  }

  network_device {
    bridge      = "vmbr0"
    mac_address = var.vm_mac_address
  }

  initialization {
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }

    user_account {
      username = "ubuntu"
      keys     = [var.ssh_public_key]
    }
  }
}
