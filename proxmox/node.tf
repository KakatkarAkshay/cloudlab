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
