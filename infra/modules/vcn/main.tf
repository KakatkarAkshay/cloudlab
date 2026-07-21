resource "oci_core_vcn" "this" {
  compartment_id = var.compartment_id
  cidr_blocks    = [var.cidr_block]
  display_name   = var.display_name
  dns_label      = var.dns_label
  is_ipv6enabled = true
}
