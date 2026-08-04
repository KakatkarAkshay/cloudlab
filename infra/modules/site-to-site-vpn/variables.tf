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
  description = "Fallback static IPv4 CIDRs retained on the IPSec connection while its tunnels use BGP."
  type        = list(string)

  validation {
    condition     = length(var.local_network_cidrs) > 0 && alltrue([for cidr in var.local_network_cidrs : can(cidrhost(cidr, 0))])
    error_message = "local_network_cidrs must contain at least one valid IPv4 CIDR."
  }
}

variable "customer_bgp_asn" {
  description = "BGP ASN used by the OpenWrt router."
  type        = number

  validation {
    condition     = var.customer_bgp_asn >= 1 && var.customer_bgp_asn <= 4294967295 && var.customer_bgp_asn != 23456
    error_message = "customer_bgp_asn must be a valid 2-byte or 4-byte ASN other than AS_TRANS (23456)."
  }
}

variable "tunnel_bgp_sessions" {
  description = "CPE and Oracle inside IPv4 and IPv6 interface addresses for the two BGP tunnels."
  type = list(object({
    customer_interface_ip   = string
    oracle_interface_ip     = string
    customer_interface_ipv6 = string
    oracle_interface_ipv6   = string
  }))

  validation {
    condition = length(var.tunnel_bgp_sessions) == 2 && alltrue([
      for session in var.tunnel_bgp_sessions :
      can(cidrnetmask(session.customer_interface_ip)) &&
      can(cidrnetmask(session.oracle_interface_ip)) &&
      contains(["30", "31"], split("/", session.customer_interface_ip)[1]) &&
      split("/", session.customer_interface_ip)[1] == split("/", session.oracle_interface_ip)[1] &&
      cidrhost(session.customer_interface_ip, 0) == cidrhost(session.oracle_interface_ip, 0) &&
      session.customer_interface_ip != session.oracle_interface_ip &&
      can(cidrhost(session.customer_interface_ipv6, 0)) &&
      can(cidrhost(session.oracle_interface_ipv6, 0)) &&
      tonumber(split("/", session.customer_interface_ipv6)[1]) >= 64 &&
      tonumber(split("/", session.customer_interface_ipv6)[1]) <= 127 &&
      split("/", session.customer_interface_ipv6)[1] == split("/", session.oracle_interface_ipv6)[1] &&
      cidrhost(session.customer_interface_ipv6, 0) == cidrhost(session.oracle_interface_ipv6, 0) &&
      session.customer_interface_ipv6 != session.oracle_interface_ipv6
    ])
    error_message = "tunnel_bgp_sessions must contain two distinct CPE/Oracle IPv4 and IPv6 address pairs from matching subnets."
  }
}

variable "display_name" {
  description = "Display name prefix for the VPN resources."
  type        = string
}
