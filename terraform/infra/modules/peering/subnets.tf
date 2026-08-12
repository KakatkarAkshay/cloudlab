resource "oci_core_subnet" "tenancy_1" {
  provider = oci.tenancy_1

  compartment_id             = var.tenancy_1_compartment_ocid
  vcn_id                     = var.tenancy_1_vcn_id
  cidr_block                 = var.tenancy_1_subnet_cidr
  ipv6cidr_block             = cidrsubnet(var.tenancy_1_vcn_ipv6_cidr, 8, 0)
  display_name               = "cloudlab-private"
  dns_label                  = "private"
  prohibit_public_ip_on_vnic = true
  prohibit_internet_ingress  = true
  route_table_id             = oci_core_route_table.tenancy_1.id
  security_list_ids          = [oci_core_security_list.tenancy_1.id]
}

resource "oci_core_subnet" "tenancy_2" {
  provider = oci.tenancy_2

  compartment_id             = var.tenancy_2_compartment_ocid
  vcn_id                     = var.tenancy_2_vcn_id
  cidr_block                 = var.tenancy_2_subnet_cidr
  ipv6cidr_block             = cidrsubnet(var.tenancy_2_vcn_ipv6_cidr, 8, 0)
  display_name               = "cloudlab-private"
  dns_label                  = "private"
  prohibit_public_ip_on_vnic = true
  prohibit_internet_ingress  = true
  route_table_id             = oci_core_route_table.tenancy_2.id
  security_list_ids          = [oci_core_security_list.tenancy_2.id]
}
