resource "oci_core_route_table" "tenancy_1" {
  provider = oci.tenancy_1

  compartment_id = var.tenancy_1_compartment_ocid
  vcn_id         = var.tenancy_1_vcn_id
  display_name   = "cloudlab-peer-routes"

  route_rules {
    destination       = var.tenancy_2_vcn_cidr
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_local_peering_gateway.requestor.id
  }

  route_rules {
    destination       = var.tenancy_2_vcn_ipv6_cidr
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_local_peering_gateway.requestor.id
  }

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.tenancy_1.id
  }

  route_rules {
    destination       = "::/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.tenancy_1.id
  }
}

resource "oci_core_route_table" "tenancy_2" {
  provider = oci.tenancy_2

  compartment_id = var.tenancy_2_compartment_ocid
  vcn_id         = var.tenancy_2_vcn_id
  display_name   = "cloudlab-peer-routes"

  route_rules {
    destination       = var.tenancy_1_vcn_cidr
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_local_peering_gateway.acceptor.id
  }

  route_rules {
    destination       = var.tenancy_1_vcn_ipv6_cidr
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_local_peering_gateway.acceptor.id
  }

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_nat_gateway.tenancy_2.id
  }

  route_rules {
    destination       = "::/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.tenancy_2.id
  }
}

resource "oci_core_nat_gateway" "tenancy_1" {
  provider = oci.tenancy_1

  compartment_id = var.tenancy_1_compartment_ocid
  vcn_id         = var.tenancy_1_vcn_id
  display_name   = "cloudlab-nat"
  block_traffic  = false
}

resource "oci_core_nat_gateway" "tenancy_2" {
  provider = oci.tenancy_2

  compartment_id = var.tenancy_2_compartment_ocid
  vcn_id         = var.tenancy_2_vcn_id
  display_name   = "cloudlab-nat"
  block_traffic  = false
}

resource "oci_core_internet_gateway" "tenancy_1" {
  provider = oci.tenancy_1

  compartment_id = var.tenancy_1_compartment_ocid
  vcn_id         = var.tenancy_1_vcn_id
  display_name   = "cloudlab-internet"
  enabled        = true
}

resource "oci_core_internet_gateway" "tenancy_2" {
  provider = oci.tenancy_2

  compartment_id = var.tenancy_2_compartment_ocid
  vcn_id         = var.tenancy_2_vcn_id
  display_name   = "cloudlab-internet"
  enabled        = true
}
