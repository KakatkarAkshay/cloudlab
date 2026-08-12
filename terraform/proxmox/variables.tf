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
  description = "VLAN carrying Proxmox management traffic."
  type        = number
  default     = 20

  validation {
    condition     = var.proxmox_management_vlan >= 1 && var.proxmox_management_vlan <= 4094
    error_message = "proxmox_management_vlan must be between 1 and 4094."
  }
}

variable "proxmox_iot_vlan" {
  description = "VLAN carrying IoT devices."
  type        = number
  default     = 10

  validation {
    condition     = var.proxmox_iot_vlan >= 1 && var.proxmox_iot_vlan <= 4094
    error_message = "proxmox_iot_vlan must be between 1 and 4094."
  }
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
