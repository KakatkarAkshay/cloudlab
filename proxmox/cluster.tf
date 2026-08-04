locals {
  cluster_versions         = jsondecode(file("${path.module}/../cluster-versions.json"))
  infra                    = data.terraform_remote_state.infra.outputs
  talos_worker_memory      = 12 * 1024
  talos_worker_subnet      = cidrsubnet(var.talos_worker_address, 0, 0)
  talos_worker_ipv6_subnet = cidrsubnet(var.talos_worker_ipv6_address, 0, 0)
}

data "terraform_remote_state" "infra" {
  backend = "oci"

  config = {
    bucket    = "cloudlab-terraform-state"
    namespace = "bms1yohq0tse"
    key       = "cloudlab/terraform.tfstate"
    region    = "ap-mumbai-1"
  }
}

data "proxmox_virtual_environment_node" "pve" {
  node_name = local.node_name
}

resource "talos_image_factory_schematic" "proxmox" {
  schematic = file("${path.module}/talos-schematic.yaml")
}

data "talos_image_factory_urls" "proxmox" {
  talos_version = local.cluster_versions.talos
  schematic_id  = talos_image_factory_schematic.proxmox.id
  platform      = "nocloud"
  architecture  = "amd64"
}

resource "proxmox_download_file" "talos" {
  content_type = "iso"
  datastore_id = proxmox_storage_directory.local.id
  node_name    = local.node_name
  url          = data.talos_image_factory_urls.proxmox.urls.iso
  file_name    = "talos-${local.cluster_versions.talos}-${talos_image_factory_schematic.proxmox.id}-amd64.iso"
  overwrite    = false
}

resource "proxmox_hardware_mapping_pci" "intel_igpu" {
  name             = "intel-igpu"
  comment          = "Intel N150 integrated GPU"
  mediated_devices = false
  map = [{
    id           = var.proxmox_igpu_pci_id
    iommu_group  = var.proxmox_igpu_iommu_group
    node         = local.node_name
    path         = var.proxmox_igpu_pci_path
    subsystem_id = var.proxmox_igpu_subsystem_id
  }]

  lifecycle {
    precondition {
      condition     = var.proxmox_igpu_iommu_group != null && var.proxmox_igpu_subsystem_id != null
      error_message = "Set proxmox_igpu_iommu_group and proxmox_igpu_subsystem_id after inspecting the Proxmox host."
    }
  }
}

resource "proxmox_virtual_environment_vm" "talos_worker" {
  name        = "chimera"
  description = "Talos control-plane node managed by Terraform"
  tags        = ["kubernetes", "talos", "terraform"]

  node_name = local.node_name
  bios      = "ovmf"
  machine   = "q35"
  started   = true
  on_boot   = true
  hotplug   = "network,disk,usb"

  agent {
    enabled = true
    trim    = true
  }

  cpu {
    cores   = data.proxmox_virtual_environment_node.pve.cpu_count
    sockets = 1
    type    = "host"
  }

  memory {
    dedicated = local.talos_worker_memory
  }

  efi_disk {
    datastore_id = proxmox_storage_lvmthin.local_lvm.id
    type         = "4m"
  }

  cdrom {
    file_id   = proxmox_download_file.talos.id
    interface = "ide0"
  }

  disk {
    datastore_id = proxmox_storage_lvmthin.local_lvm.id
    interface    = "scsi0"
    cache        = "none"
    discard      = "on"
    file_format  = "raw"
    size         = var.talos_worker_disk_size
  }

  initialization {
    datastore_id = proxmox_storage_lvmthin.local_lvm.id
    interface    = "ide2"

    ip_config {
      ipv4 {
        address = var.talos_worker_address
        gateway = var.proxmox_bridge_gateway
      }
      ipv6 {
        address = var.talos_worker_ipv6_address
        gateway = var.talos_worker_ipv6_gateway
      }
    }
  }

  network_device {
    bridge  = proxmox_network_linux_bridge.management.name
    model   = "virtio"
    queues  = data.proxmox_virtual_environment_node.pve.cpu_count
    vlan_id = var.proxmox_management_vlan
  }

  hostpci {
    device  = "hostpci0"
    mapping = proxmox_hardware_mapping_pci.intel_igpu.name
    pcie    = true
    rombar  = true
  }

  operating_system {
    type = "l26"
  }

  serial_device {}

  vga {
    type = "serial0"
  }

  boot_order      = ["scsi0", "ide0"]
  scsi_hardware   = "virtio-scsi-pci"
  stop_on_destroy = true
}

resource "talos_machine_configuration_apply" "proxmox_worker" {
  depends_on = [proxmox_virtual_environment_vm.talos_worker]

  node                        = split("/", var.talos_worker_address)[0]
  endpoint                    = split("/", var.talos_worker_address)[0]
  client_configuration        = local.infra.talos_client_configuration
  machine_configuration_input = local.infra.machine_configuration_control_plane
  config_patches = [
    yamlencode({
      cluster = {
        controlPlane = {
          endpoint = "https://${local.infra.control_plane_private_ip}:6443"
        }
        externalCloudProvider = {
          enabled = false
        }
        etcd = {
          advertisedSubnets = [local.talos_worker_subnet, local.talos_worker_ipv6_subnet]
        }
      }
      machine = {
        install = {
          image = data.talos_image_factory_urls.proxmox.urls.installer
        }
        kernel = {
          modules = [
            { name = "binfmt_misc" },
            { name = "i915" },
          ]
        }
        kubelet = {
          nodeIP = {
            validSubnets = [local.talos_worker_subnet, local.talos_worker_ipv6_subnet]
          }
        }
        nodeLabels = {
          "intel.feature.node.kubernetes.io/gpu" = "true"
        }
        time = {
          servers = ["time.cloudflare.com"]
        }
      }
    }),
  ]

  timeouts = {
    create = "15m"
  }
}
