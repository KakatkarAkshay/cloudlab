resource "oci_core_security_list" "tenancy_1" {
  provider = oci.tenancy_1

  compartment_id = var.tenancy_1_compartment_ocid
  vcn_id         = var.tenancy_1_vcn_id
  display_name   = "cloudlab-private-subnet"

  ingress_security_rules {
    protocol    = "all"
    source      = var.tenancy_1_vcn_cidr
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "Allow traffic within the requestor VCN"
  }

  ingress_security_rules {
    protocol    = "all"
    source      = var.tenancy_2_vcn_cidr
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "Allow all traffic from the acceptor VCN"
  }

  ingress_security_rules {
    protocol    = "all"
    source      = var.tenancy_1_vcn_ipv6_cidr
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "Allow IPv6 traffic within the requestor VCN"
  }

  ingress_security_rules {
    protocol    = "all"
    source      = var.tenancy_2_vcn_ipv6_cidr
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "Allow IPv6 traffic from the acceptor VCN"
  }

  egress_security_rules {
    protocol         = "all"
    destination      = var.tenancy_1_vcn_cidr
    destination_type = "CIDR_BLOCK"
    stateless        = false
    description      = "Allow traffic within the requestor VCN"
  }

  egress_security_rules {
    protocol         = "all"
    destination      = var.tenancy_2_vcn_cidr
    destination_type = "CIDR_BLOCK"
    stateless        = false
    description      = "Allow outbound traffic to the acceptor VCN"
  }

  egress_security_rules {
    protocol         = "all"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    stateless        = false
    description      = "Allow outbound internet access"
  }

  egress_security_rules {
    protocol         = "all"
    destination      = "::/0"
    destination_type = "CIDR_BLOCK"
    stateless        = false
    description      = "Allow outbound IPv6 access"
  }
}

resource "oci_core_security_list" "tenancy_2" {
  provider = oci.tenancy_2

  compartment_id = var.tenancy_2_compartment_ocid
  vcn_id         = var.tenancy_2_vcn_id
  display_name   = "cloudlab-private-subnet"

  ingress_security_rules {
    protocol    = "all"
    source      = var.tenancy_2_vcn_cidr
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "Allow traffic within the acceptor VCN"
  }

  ingress_security_rules {
    protocol    = "all"
    source      = var.tenancy_1_vcn_cidr
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "Allow all traffic from the requestor VCN"
  }

  ingress_security_rules {
    protocol    = "all"
    source      = var.tenancy_2_vcn_ipv6_cidr
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "Allow IPv6 traffic within the acceptor VCN"
  }

  ingress_security_rules {
    protocol    = "all"
    source      = var.tenancy_1_vcn_ipv6_cidr
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "Allow IPv6 traffic from the requestor VCN"
  }

  egress_security_rules {
    protocol         = "all"
    destination      = var.tenancy_2_vcn_cidr
    destination_type = "CIDR_BLOCK"
    stateless        = false
    description      = "Allow traffic within the acceptor VCN"
  }

  egress_security_rules {
    protocol         = "all"
    destination      = var.tenancy_1_vcn_cidr
    destination_type = "CIDR_BLOCK"
    stateless        = false
    description      = "Allow outbound traffic to the requestor VCN"
  }

  egress_security_rules {
    protocol         = "all"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    stateless        = false
    description      = "Allow outbound internet access"
  }

  egress_security_rules {
    protocol         = "all"
    destination      = "::/0"
    destination_type = "CIDR_BLOCK"
    stateless        = false
    description      = "Allow outbound IPv6 access"
  }
}
