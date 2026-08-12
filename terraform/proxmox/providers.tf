locals {
  node_name = "pve"
  endpoint  = "https://${split("/", var.proxmox_bridge_address)[0]}:8006"
}

provider "proxmox" {
  endpoint  = local.endpoint
  api_token = var.proxmox_api_token
  insecure  = true
}
