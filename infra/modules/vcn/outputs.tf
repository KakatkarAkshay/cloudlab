output "id" {
  description = "OCID of the VCN."
  value       = oci_core_vcn.this.id
}

output "cidr_block" {
  description = "IPv4 CIDR of the VCN."
  value       = oci_core_vcn.this.cidr_blocks[0]
}

output "ipv6_cidr_block" {
  description = "Oracle-assigned IPv6 /56 CIDR of the VCN."
  value       = try(oci_core_vcn.this.ipv6cidr_blocks[0], null)
}
