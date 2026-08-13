locals {
  cluster_api_ip = one([
    for address in oci_network_load_balancer_network_load_balancer.control_plane.ip_addresses : address.ip_address
    if address.ip_version == "IPV4" && address.is_public
  ])
  cluster_api_addresses = [
    for address in oci_network_load_balancer_network_load_balancer.control_plane.ip_addresses : address.ip_address
    if address.is_public
  ]
}

resource "oci_core_security_list" "nlb" {
  provider = oci.tenancy_1

  compartment_id = var.tenancy_1_compartment_ocid
  vcn_id         = module.tenancy_1_vcn.id
  display_name   = "cloudlab-nlb"

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "Kubernetes API"

    tcp_options {
      min = 6443
      max = 6443
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "::/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "Kubernetes API over IPv6"

    tcp_options {
      min = 6443
      max = 6443
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "HTTP ingress proof"

    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "::/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "HTTP ingress proof over IPv6"

    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "HTTPS ingress proof"

    tcp_options {
      min = 443
      max = 443
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "::/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "HTTPS ingress proof over IPv6"

    tcp_options {
      min = 443
      max = 443
    }
  }

  ingress_security_rules {
    protocol    = "17"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "WireGuard tunnel for Pangolin sites"

    udp_options {
      min = 51820
      max = 51820
    }
  }

  ingress_security_rules {
    protocol    = "17"
    source      = "::/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "WireGuard tunnel for Pangolin sites over IPv6"

    udp_options {
      min = 51820
      max = 51820
    }
  }

  ingress_security_rules {
    protocol    = "17"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "NAT hole punch for Pangolin sites"

    udp_options {
      min = 21820
      max = 21820
    }
  }

  ingress_security_rules {
    protocol    = "17"
    source      = "::/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "NAT hole punch for Pangolin sites over IPv6"

    udp_options {
      min = 21820
      max = 21820
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "Talos API"

    tcp_options {
      min = 50000
      max = 50000
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "::/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "Talos API over IPv6"

    tcp_options {
      min = 50000
      max = 50000
    }
  }

  egress_security_rules {
    protocol         = "all"
    destination      = var.tenancy_1_subnet_cidr
    destination_type = "CIDR_BLOCK"
    stateless        = false
    description      = "Control plane backends"
  }

  egress_security_rules {
    protocol         = "all"
    destination      = module.tenancy_1_vcn.ipv6_cidr_block
    destination_type = "CIDR_BLOCK"
    stateless        = false
    description      = "Control plane IPv6 backends"
  }

  egress_security_rules {
    protocol         = "all"
    destination      = var.tenancy_2_subnet_cidr
    destination_type = "CIDR_BLOCK"
    stateless        = false
    description      = "Worker backends"
  }

  egress_security_rules {
    protocol         = "all"
    destination      = module.tenancy_2_vcn.ipv6_cidr_block
    destination_type = "CIDR_BLOCK"
    stateless        = false
    description      = "Worker IPv6 backends"
  }


}

resource "oci_core_security_list" "nlb_tenancy_2" {
  provider = oci.tenancy_2

  compartment_id = var.tenancy_2_compartment_ocid
  vcn_id         = module.tenancy_2_vcn.id
  display_name   = "cloudlab-nlb"

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "HTTP ingress"

    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "::/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "HTTP ingress over IPv6"

    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "HTTPS ingress"

    tcp_options {
      min = 443
      max = 443
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "::/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "HTTPS ingress over IPv6"

    tcp_options {
      min = 443
      max = 443
    }
  }

  ingress_security_rules {
    protocol    = "17"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "WireGuard tunnel for Pangolin sites"

    udp_options {
      min = 51820
      max = 51820
    }
  }

  ingress_security_rules {
    protocol    = "17"
    source      = "::/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "WireGuard tunnel for Pangolin sites over IPv6"

    udp_options {
      min = 51820
      max = 51820
    }
  }

  ingress_security_rules {
    protocol    = "17"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "NAT hole punch for Pangolin sites"

    udp_options {
      min = 21820
      max = 21820
    }
  }

  ingress_security_rules {
    protocol    = "17"
    source      = "::/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "NAT hole punch for Pangolin sites over IPv6"

    udp_options {
      min = 21820
      max = 21820
    }
  }

  egress_security_rules {
    protocol         = "all"
    destination      = var.tenancy_2_subnet_cidr
    destination_type = "CIDR_BLOCK"
    stateless        = false
    description      = "Worker backends"
  }

  egress_security_rules {
    protocol         = "all"
    destination      = module.tenancy_2_vcn.ipv6_cidr_block
    destination_type = "CIDR_BLOCK"
    stateless        = false
    description      = "Worker IPv6 backends"
  }

  egress_security_rules {
    protocol         = "all"
    destination      = var.tenancy_1_subnet_cidr
    destination_type = "CIDR_BLOCK"
    stateless        = false
    description      = "Control plane backends"
  }

  egress_security_rules {
    protocol         = "all"
    destination      = module.tenancy_1_vcn.ipv6_cidr_block
    destination_type = "CIDR_BLOCK"
    stateless        = false
    description      = "Control plane IPv6 backends"
  }
}

resource "oci_core_subnet" "nlb" {
  provider = oci.tenancy_1

  compartment_id             = var.tenancy_1_compartment_ocid
  vcn_id                     = module.tenancy_1_vcn.id
  cidr_block                 = cidrsubnet(var.tenancy_1_vcn_cidr, 8, 1)
  ipv6cidr_block             = cidrsubnet(module.tenancy_1_vcn.ipv6_cidr_block, 8, 1)
  display_name               = "cloudlab-nlb"
  dns_label                  = "nlb"
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.nlb.id
  security_list_ids          = [oci_core_security_list.nlb.id]
}

resource "oci_core_subnet" "nlb_tenancy_2" {
  provider = oci.tenancy_2

  compartment_id             = var.tenancy_2_compartment_ocid
  vcn_id                     = module.tenancy_2_vcn.id
  cidr_block                 = cidrsubnet(var.tenancy_2_vcn_cidr, 8, 1)
  ipv6cidr_block             = cidrsubnet(module.tenancy_2_vcn.ipv6_cidr_block, 8, 1)
  display_name               = "cloudlab-nlb"
  dns_label                  = "nlb"
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.nlb_tenancy_2.id
  security_list_ids          = [oci_core_security_list.nlb_tenancy_2.id]
}

resource "oci_core_route_table" "nlb" {
  provider = oci.tenancy_1

  compartment_id = var.tenancy_1_compartment_ocid
  vcn_id         = module.tenancy_1_vcn.id
  display_name   = "cloudlab-nlb-routes"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = module.cross_tenancy_peering.tenancy_1_internet_gateway_id
  }

  route_rules {
    destination       = "::/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = module.cross_tenancy_peering.tenancy_1_internet_gateway_id
  }

  route_rules {
    destination       = var.tenancy_2_vcn_cidr
    destination_type  = "CIDR_BLOCK"
    network_entity_id = module.cross_tenancy_peering.tenancy_1_local_peering_gateway_id
  }

  route_rules {
    destination       = module.tenancy_2_vcn.ipv6_cidr_block
    destination_type  = "CIDR_BLOCK"
    network_entity_id = module.cross_tenancy_peering.tenancy_1_local_peering_gateway_id
  }


}

resource "oci_core_route_table" "nlb_tenancy_2" {
  provider = oci.tenancy_2

  compartment_id = var.tenancy_2_compartment_ocid
  vcn_id         = module.tenancy_2_vcn.id
  display_name   = "cloudlab-nlb-routes"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = module.cross_tenancy_peering.tenancy_2_internet_gateway_id
  }

  route_rules {
    destination       = "::/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = module.cross_tenancy_peering.tenancy_2_internet_gateway_id
  }

  route_rules {
    destination       = var.tenancy_1_vcn_cidr
    destination_type  = "CIDR_BLOCK"
    network_entity_id = module.cross_tenancy_peering.tenancy_2_local_peering_gateway_id
  }

  route_rules {
    destination       = module.tenancy_1_vcn.ipv6_cidr_block
    destination_type  = "CIDR_BLOCK"
    network_entity_id = module.cross_tenancy_peering.tenancy_2_local_peering_gateway_id
  }


}

resource "oci_core_public_ip" "control_plane" {
  provider = oci.tenancy_1

  compartment_id = var.tenancy_1_compartment_ocid
  display_name   = "cloudlab-control-plane"
  lifetime       = "RESERVED"

  # reserved_ips binds this to the NLB out-of-band; ignore the resulting private_ip_id.
  lifecycle {
    ignore_changes = [private_ip_id]
  }
}

resource "oci_network_load_balancer_network_load_balancer" "control_plane" {
  provider = oci.tenancy_1

  compartment_id                 = var.tenancy_1_compartment_ocid
  display_name                   = "cloudlab-control-plane"
  subnet_id                      = oci_core_subnet.nlb.id
  is_private                     = false
  is_preserve_source_destination = false
  nlb_ip_version                 = "IPV4_AND_IPV6"

  reserved_ips {
    id = oci_core_public_ip.control_plane.id
  }
}

resource "oci_network_load_balancer_backend_set" "kubernetes" {
  provider = oci.tenancy_1

  name                     = "kubernetes"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.control_plane.id
  policy                   = "TWO_TUPLE"
  is_preserve_source       = false
  ip_version               = "IPV4"

  health_checker {
    protocol           = "HTTPS"
    port               = 6443
    url_path           = "/readyz"
    return_code        = 401
    interval_in_millis = 10000
    timeout_in_millis  = 3000
    retries            = 3
  }
}

resource "oci_network_load_balancer_backend_set" "kubernetes_ipv6" {
  provider = oci.tenancy_1

  name                     = "kubernetes-ipv6"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.control_plane.id
  policy                   = "TWO_TUPLE"
  is_preserve_source       = false
  ip_version               = "IPV6"

  health_checker {
    protocol           = "HTTPS"
    port               = 6443
    url_path           = "/readyz"
    return_code        = 401
    interval_in_millis = 10000
    timeout_in_millis  = 3000
    retries            = 3
  }
}

resource "oci_network_load_balancer_backend_set" "talos" {
  provider = oci.tenancy_1

  name                     = "talos"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.control_plane.id
  policy                   = "TWO_TUPLE"
  is_preserve_source       = false
  ip_version               = "IPV4"

  health_checker {
    protocol           = "TCP"
    port               = 50000
    interval_in_millis = 10000
    timeout_in_millis  = 3000
    retries            = 3
  }
}

resource "oci_network_load_balancer_backend_set" "talos_ipv6" {
  provider = oci.tenancy_1

  name                     = "talos-ipv6"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.control_plane.id
  policy                   = "TWO_TUPLE"
  is_preserve_source       = false
  ip_version               = "IPV6"

  health_checker {
    protocol           = "TCP"
    port               = 50000
    interval_in_millis = 10000
    timeout_in_millis  = 3000
    retries            = 3
  }
}

resource "oci_network_load_balancer_backend" "kubernetes" {
  provider = oci.tenancy_1
  for_each = local.control_plane_nodes

  backend_set_name         = oci_network_load_balancer_backend_set.kubernetes.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.control_plane.id
  ip_address               = each.value.ip
  port                     = 6443
  name                     = each.key
}

resource "oci_network_load_balancer_backend" "kubernetes_ipv6" {
  provider = oci.tenancy_1
  for_each = local.control_plane_nodes

  backend_set_name         = oci_network_load_balancer_backend_set.kubernetes_ipv6.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.control_plane.id
  ip_address               = each.value.ipv6
  port                     = 6443
  name                     = "${each.key}-kubernetes-ipv6"
}

resource "oci_network_load_balancer_backend" "talos" {
  provider = oci.tenancy_1
  for_each = local.control_plane_nodes

  backend_set_name         = oci_network_load_balancer_backend_set.talos.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.control_plane.id
  ip_address               = each.value.ip
  port                     = 50000
  name                     = "${each.key}-talos"
}

resource "oci_network_load_balancer_backend" "talos_ipv6" {
  provider = oci.tenancy_1
  for_each = local.control_plane_nodes

  backend_set_name         = oci_network_load_balancer_backend_set.talos_ipv6.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.control_plane.id
  ip_address               = each.value.ipv6
  port                     = 50000
  name                     = "${each.key}-talos-ipv6"
}

resource "oci_network_load_balancer_listener" "kubernetes" {
  provider = oci.tenancy_1
  for_each = toset(["IPV4", "IPV6"])

  default_backend_set_name = each.value == "IPV4" ? oci_network_load_balancer_backend_set.kubernetes.name : oci_network_load_balancer_backend_set.kubernetes_ipv6.name
  name                     = "kubernetes-${lower(each.value)}"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.control_plane.id
  port                     = 6443
  protocol                 = "TCP"
  ip_version               = each.value
}

resource "oci_network_load_balancer_listener" "talos" {
  provider = oci.tenancy_1
  for_each = toset(["IPV4", "IPV6"])

  default_backend_set_name = each.value == "IPV4" ? oci_network_load_balancer_backend_set.talos.name : oci_network_load_balancer_backend_set.talos_ipv6.name
  name                     = "talos-${lower(each.value)}"
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.control_plane.id
  port                     = 50000
  protocol                 = "TCP"
  ip_version               = each.value
}
