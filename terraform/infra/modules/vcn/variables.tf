variable "compartment_id" {
  description = "Compartment OCID where the VCN is created."
  type        = string
}

variable "cidr_block" {
  description = "IPv4 CIDR assigned to the VCN."
  type        = string
}

variable "display_name" {
  description = "Display name for the VCN."
  type        = string
}

variable "dns_label" {
  description = "DNS label for the VCN."
  type        = string
}
