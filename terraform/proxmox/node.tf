resource "proxmox_network_linux_bridge" "management" {
  node_name  = local.node_name
  name       = "vmbr0"
  ports      = ["nic0"]
  vlan_aware = true
  vids       = join(" ", sort([tostring(var.proxmox_iot_vlan), tostring(var.proxmox_management_vlan)]))
}

resource "proxmox_network_linux_vlan" "management" {
  node_name = local.node_name
  name      = "vmbr0.${var.proxmox_management_vlan}"
  address   = var.proxmox_bridge_address
  gateway   = var.proxmox_bridge_gateway
}

resource "proxmox_storage_directory" "local" {
  id      = "local"
  path    = "/var/lib/vz"
  content = ["backup", "import", "iso", "vztmpl"]
  shared  = false
}

resource "proxmox_storage_lvmthin" "local_lvm" {
  id           = "local-lvm"
  volume_group = "pve"
  thin_pool    = "data"
  content      = ["images", "rootdir"]
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
