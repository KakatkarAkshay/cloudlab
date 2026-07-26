variable "compartment_id" {
  description = "Compartment OCID where the VPN resources are created."
  type        = string
}

variable "vcn_id" {
  description = "OCID of the VCN attached to the VPN DRG."
  type        = string
}

variable "cpe_public_ip" {
  description = "Public IPv4 address of the OpenWrt router."
  type        = string

  validation {
    condition     = can(cidrhost("${var.cpe_public_ip}/32", 0))
    error_message = "cpe_public_ip must be a valid IPv4 address."
  }
}

variable "local_network_cidrs" {
  description = "Local IPv4 CIDRs routed through the OpenWrt router."
  type        = list(string)

  validation {
    condition     = length(var.local_network_cidrs) > 0 && alltrue([for cidr in var.local_network_cidrs : can(cidrhost(cidr, 0))])
    error_message = "local_network_cidrs must contain at least one valid IPv4 CIDR."
  }
}

variable "display_name" {
  description = "Display name prefix for the VPN resources."
  type        = string
}
