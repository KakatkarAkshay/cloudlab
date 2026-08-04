resource "proxmox_apt_standard_repository" "no_subscription" {
  node   = local.node_name
  handle = "no-subscription"
}

resource "proxmox_apt_repository" "no_subscription" {
  node      = local.node_name
  file_path = proxmox_apt_standard_repository.no_subscription.file_path
  index     = proxmox_apt_standard_repository.no_subscription.index
  enabled   = true
}
