variable "proxmox_api_token" {
  description = "Proxmox VE API token in user@realm!tokenid=uuid form."
  type        = string
  sensitive   = true
}

variable "proxmox_bridge_address" {
  description = "IPv4 CIDR address assigned to the management VLAN interface."
  type        = string
  default     = "192.168.20.2/24"

  validation {
    condition     = can(cidrnetmask(var.proxmox_bridge_address))
    error_message = "proxmox_bridge_address must be an IPv4 CIDR, e.g. 10.0.0.2/24."
  }
}

variable "proxmox_bridge_gateway" {
  description = "Default gateway reachable over the management VLAN."
  type        = string
  default     = "192.168.20.1"

  validation {
    condition     = can(cidrhost("${var.proxmox_bridge_gateway}/32", 0))
    error_message = "proxmox_bridge_gateway must be a valid IPv4 address."
  }
}

variable "proxmox_management_vlan" {
  description = "VLAN carrying Proxmox and Talos management traffic."
  type        = number
  default     = 20

  validation {
    condition     = var.proxmox_management_vlan >= 1 && var.proxmox_management_vlan <= 4094
    error_message = "proxmox_management_vlan must be between 1 and 4094."
  }
}

variable "talos_worker_address" {
  description = "Static IPv4 CIDR assigned to the Proxmox Talos worker."
  type        = string
  default     = "192.168.20.3/24"

  validation {
    condition     = can(cidrnetmask(var.talos_worker_address))
    error_message = "talos_worker_address must be an IPv4 CIDR."
  }
}

variable "talos_worker_ipv6_address" {
  description = "Static IPv6 CIDR assigned to the Proxmox Talos worker."
  type        = string
  default     = "fd51:86b9:78d0:20::3/64"
}

variable "talos_worker_ipv6_gateway" {
  description = "IPv6 gateway for the Proxmox Talos worker."
  type        = string
  default     = "fd51:86b9:78d0:20::1"
}

variable "talos_worker_disk_size" {
  description = "Thin-provisioned Talos worker disk size in GiB."
  type        = number
  default     = 200
}

variable "proxmox_igpu_pci_id" {
  description = "PCI vendor and device ID of the Intel N150 iGPU."
  type        = string
  default     = "8086:46d4"
}

variable "proxmox_igpu_pci_path" {
  description = "PCI address of the Intel N150 iGPU."
  type        = string
  default     = "0000:00:02.0"
}

variable "proxmox_igpu_iommu_group" {
  description = "IOMMU group of the Intel iGPU."
  type        = number
  default     = 0
}

variable "proxmox_igpu_subsystem_id" {
  description = "PCI subsystem ID of the Intel iGPU."
  type        = string
  default     = "1043:88e8"
}
