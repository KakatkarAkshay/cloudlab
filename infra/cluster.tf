locals {
  cluster_versions   = jsondecode(file("${path.module}/../cluster-versions.json"))
  talos_image_object = "talos-${local.cluster_versions.talos}-${talos_image_factory_schematic.cluster.id}-oracle-arm64.qcow2"
  talos_image_path   = "${path.module}/build/${local.talos_image_object}"
  nodes = {
    for ordinal in range(var.control_plane_count + var.worker_count) :
    (ordinal < var.control_plane_count ? "controlplane-${ordinal}" : "worker-${ordinal - var.control_plane_count}") => {
      role       = ordinal < var.control_plane_count ? "controlplane" : "worker"
      tenancy    = ordinal % 2 + 1
      host_index = var.node_host_index_base + floor(ordinal / 2)
      ip = cidrhost(
        ordinal % 2 == 0 ? var.tenancy_1_subnet_cidr : var.tenancy_2_subnet_cidr,
        var.node_host_index_base + floor(ordinal / 2),
      )
      ipv6 = cidrhost(
        cidrsubnet(ordinal % 2 == 0 ? module.tenancy_1_vcn.ipv6_cidr_block : module.tenancy_2_vcn.ipv6_cidr_block, 8, 0),
        var.node_host_index_base + floor(ordinal / 2),
      )
      ipv6_subnet_cidr = cidrsubnet(
        ordinal % 2 == 0 ? module.tenancy_1_vcn.ipv6_cidr_block : module.tenancy_2_vcn.ipv6_cidr_block, 8, 0,
      )
    }
  }

  control_plane_nodes = { for name, node in local.nodes : name => node if node.role == "controlplane" }

  bootstrap_ip = local.nodes["controlplane-0"].ip
  cluster_api_ip = one([
    for address in oci_network_load_balancer_network_load_balancer.control_plane.ip_addresses : address.ip_address
    if address.ip_version == "IPV4" && address.is_public
  ])
  cluster_api_addresses = [
    for address in oci_network_load_balancer_network_load_balancer.control_plane.ip_addresses : address.ip_address
    if address.is_public
  ]
  talos_image_capabilities = {
    "Compute.Firmware" = jsonencode({
      descriptorType = "enumstring"
      source         = "IMAGE"
      defaultValue   = "UEFI_64"
      values         = ["UEFI_64"]
    })
    "Network.AttachmentType" = jsonencode({
      descriptorType = "enumstring"
      source         = "IMAGE"
      defaultValue   = "PARAVIRTUALIZED"
      values         = ["PARAVIRTUALIZED"]
    })
    "Storage.BootVolumeType" = jsonencode({
      descriptorType = "enumstring"
      source         = "IMAGE"
      defaultValue   = "PARAVIRTUALIZED"
      values         = ["PARAVIRTUALIZED"]
    })
    "Storage.RemoteDataVolumeType" = jsonencode({
      descriptorType = "enumstring"
      source         = "IMAGE"
      defaultValue   = "PARAVIRTUALIZED"
      values         = ["PARAVIRTUALIZED"]
    })
    "Storage.ConsistentVolumeNaming" = jsonencode({
      descriptorType = "boolean"
      source         = "IMAGE"
      defaultValue   = true
    })
    "Storage.ParaVirtualization.EncryptionInTransit" = jsonencode({
      descriptorType = "boolean"
      source         = "IMAGE"
      defaultValue   = true
    })
  }
}

resource "talos_image_factory_schematic" "cluster" {
  schematic = file("${path.module}/talos-schematic.yaml")
}

data "talos_image_factory_urls" "oracle_arm64" {
  talos_version = local.cluster_versions.talos
  schematic_id  = talos_image_factory_schematic.cluster.id
  platform      = "oracle"
  architecture  = "arm64"
}

data "local_command" "talos_image" {
  command = "curl"
  arguments = [
    "--fail",
    "--location",
    "--silent",
    "--show-error",
    "--create-dirs",
    "--output",
    local.talos_image_path,
    data.talos_image_factory_urls.oracle_arm64.urls.disk_image,
  ]
}

data "oci_identity_availability_domains" "tenancy_1" {
  provider = oci.tenancy_1

  compartment_id = var.tenancy_1_compartment_ocid
}

data "oci_identity_availability_domains" "tenancy_2" {
  provider = oci.tenancy_2

  compartment_id = var.tenancy_2_compartment_ocid
}

resource "oci_objectstorage_bucket" "talos_tenancy_1" {
  provider = oci.tenancy_1

  compartment_id = var.tenancy_1_compartment_ocid
  namespace      = data.oci_objectstorage_namespace.tenancy_1.namespace
  name           = "cloudlab-talos-images"
  access_type    = "NoPublicAccess"
}

resource "oci_objectstorage_bucket" "talos_tenancy_2" {
  provider = oci.tenancy_2

  compartment_id = var.tenancy_2_compartment_ocid
  namespace      = data.oci_objectstorage_namespace.tenancy_2.namespace
  name           = "cloudlab-talos-images"
  access_type    = "NoPublicAccess"
}

resource "oci_objectstorage_object" "talos_tenancy_1" {
  provider = oci.tenancy_1

  bucket    = oci_objectstorage_bucket.talos_tenancy_1.name
  namespace = data.oci_objectstorage_namespace.tenancy_1.namespace
  object    = local.talos_image_object
  source    = local.talos_image_path

  depends_on = [data.local_command.talos_image]

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [source]
  }
}

resource "oci_objectstorage_object" "talos_tenancy_2" {
  provider = oci.tenancy_2

  bucket    = oci_objectstorage_bucket.talos_tenancy_2.name
  namespace = data.oci_objectstorage_namespace.tenancy_2.namespace
  object    = local.talos_image_object
  source    = local.talos_image_path

  depends_on = [data.local_command.talos_image]

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [source]
  }
}

resource "oci_core_image" "talos_tenancy_1" {
  provider = oci.tenancy_1

  compartment_id = var.tenancy_1_compartment_ocid
  display_name   = "Talos ${local.cluster_versions.talos} ARM64"
  launch_mode    = "PARAVIRTUALIZED"

  image_source_details {
    source_type              = "objectStorageTuple"
    namespace_name           = data.oci_objectstorage_namespace.tenancy_1.namespace
    bucket_name              = oci_objectstorage_bucket.talos_tenancy_1.name
    object_name              = oci_objectstorage_object.talos_tenancy_1.object
    operating_system         = "Talos"
    operating_system_version = trimprefix(local.cluster_versions.talos, "v")
    source_image_type        = "QCOW2"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [display_name, image_source_details]
  }
}

resource "oci_core_image" "talos_tenancy_2" {
  provider = oci.tenancy_2

  compartment_id = var.tenancy_2_compartment_ocid
  display_name   = "Talos ${local.cluster_versions.talos} ARM64"
  launch_mode    = "PARAVIRTUALIZED"

  image_source_details {
    source_type              = "objectStorageTuple"
    namespace_name           = data.oci_objectstorage_namespace.tenancy_2.namespace
    bucket_name              = oci_objectstorage_bucket.talos_tenancy_2.name
    object_name              = oci_objectstorage_object.talos_tenancy_2.object
    operating_system         = "Talos"
    operating_system_version = trimprefix(local.cluster_versions.talos, "v")
    source_image_type        = "QCOW2"
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [display_name, image_source_details]
  }
}

data "oci_core_compute_global_image_capability_schemas" "tenancy_1" {
  provider = oci.tenancy_1
}

data "oci_core_compute_global_image_capability_schema" "tenancy_1" {
  provider = oci.tenancy_1

  compute_global_image_capability_schema_id = data.oci_core_compute_global_image_capability_schemas.tenancy_1.compute_global_image_capability_schemas[0].id
}

data "oci_core_compute_global_image_capability_schemas" "tenancy_2" {
  provider = oci.tenancy_2
}

data "oci_core_compute_global_image_capability_schema" "tenancy_2" {
  provider = oci.tenancy_2

  compute_global_image_capability_schema_id = data.oci_core_compute_global_image_capability_schemas.tenancy_2.compute_global_image_capability_schemas[0].id
}

resource "oci_core_compute_image_capability_schema" "talos_tenancy_1" {
  provider = oci.tenancy_1

  compartment_id                                      = var.tenancy_1_compartment_ocid
  compute_global_image_capability_schema_version_name = data.oci_core_compute_global_image_capability_schema.tenancy_1.current_version_name
  display_name                                        = "Talos ARM64 capabilities"
  image_id                                            = oci_core_image.talos_tenancy_1.id
  schema_data                                         = local.talos_image_capabilities
}

resource "oci_core_compute_image_capability_schema" "talos_tenancy_2" {
  provider = oci.tenancy_2

  compartment_id                                      = var.tenancy_2_compartment_ocid
  compute_global_image_capability_schema_version_name = data.oci_core_compute_global_image_capability_schema.tenancy_2.current_version_name
  display_name                                        = "Talos ARM64 capabilities"
  image_id                                            = oci_core_image.talos_tenancy_2.id
  schema_data                                         = local.talos_image_capabilities
}

resource "oci_core_shape_management" "talos_tenancy_1" {
  provider = oci.tenancy_1

  compartment_id = var.tenancy_1_compartment_ocid
  image_id       = oci_core_image.talos_tenancy_1.id
  shape_name     = "VM.Standard.A1.Flex"

  depends_on = [oci_core_compute_image_capability_schema.talos_tenancy_1]
}

resource "oci_core_shape_management" "talos_tenancy_2" {
  provider = oci.tenancy_2

  compartment_id = var.tenancy_2_compartment_ocid
  image_id       = oci_core_image.talos_tenancy_2.id
  shape_name     = "VM.Standard.A1.Flex"

  depends_on = [oci_core_compute_image_capability_schema.talos_tenancy_2]
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

  dynamic "egress_security_rules" {
    for_each = var.local_network_cidrs

    content {
      protocol         = "all"
      destination      = egress_security_rules.value
      destination_type = "CIDR_BLOCK"
      stateless        = false
      description      = "Local control-plane backends"
    }
  }

  dynamic "egress_security_rules" {
    for_each = var.local_ipv6_cidrs

    content {
      protocol         = "all"
      destination      = egress_security_rules.value
      destination_type = "CIDR_BLOCK"
      stateless        = false
      description      = "Local IPv6 control-plane backends"
    }
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

  dynamic "route_rules" {
    for_each = var.local_network_cidrs

    content {
      destination       = route_rules.value
      destination_type  = "CIDR_BLOCK"
      network_entity_id = module.tenancy_1_site_to_site_vpn.drg_id
    }
  }

  dynamic "route_rules" {
    for_each = var.local_ipv6_cidrs

    content {
      destination       = route_rules.value
      destination_type  = "CIDR_BLOCK"
      network_entity_id = module.tenancy_1_site_to_site_vpn.drg_id
    }
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

  dynamic "route_rules" {
    for_each = var.local_network_cidrs

    content {
      destination       = route_rules.value
      destination_type  = "CIDR_BLOCK"
      network_entity_id = module.tenancy_2_site_to_site_vpn.drg_id
    }
  }

  dynamic "route_rules" {
    for_each = var.local_ipv6_cidrs

    content {
      destination       = route_rules.value
      destination_type  = "CIDR_BLOCK"
      network_entity_id = module.tenancy_2_site_to_site_vpn.drg_id
    }
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

resource "talos_machine_secrets" "cluster" {
  talos_version = local.cluster_versions.talos
}

data "talos_machine_configuration" "control_plane" {
  cluster_name       = var.cluster_name
  machine_type       = "controlplane"
  cluster_endpoint   = "https://${local.bootstrap_ip}:6443"
  machine_secrets    = talos_machine_secrets.cluster.machine_secrets
  talos_version      = local.cluster_versions.talos
  kubernetes_version = local.cluster_versions.kubernetes

  config_patches = [
    yamlencode({
      machine = {
        nodeLabels = {
          "node.longhorn.io/create-default-disk" = "true"
          "topology.cloudlab.io/location"        = "oci"
        }
        certSANs = local.cluster_api_addresses
        kernel = {
          modules = [
            { name = "binfmt_misc" },
          ]
        }
        sysctls = {
          "net.ipv4.ip_forward"          = "1"
          "net.ipv6.conf.all.forwarding" = "1"
        }
        time = {
          servers = ["169.254.169.254"]
        }
        kubelet = {
          extraArgs = {
            rotate-server-certificates = "true"
          }
          extraMounts = [
            {
              destination = "/var/lib/longhorn"
              source      = "/var/mnt/longhorn"
              type        = "bind"
              options     = ["bind", "rshared", "rw"]
            },
          ]
          nodeIP = {
            validSubnets = [
              var.tenancy_1_vcn_cidr,
              module.tenancy_1_vcn.ipv6_cidr_block,
              var.tenancy_2_vcn_cidr,
              module.tenancy_2_vcn.ipv6_cidr_block,
            ]
          }
        }
      }
      cluster = {
        allowSchedulingOnControlPlanes = true
        network = {
          podSubnets     = var.kubernetes_pod_subnets
          serviceSubnets = var.kubernetes_service_subnets
        }
        apiServer = {
          certSANs = local.cluster_api_addresses
        }
        controllerManager = {
          extraArgs = {
            bind-address = "0.0.0.0"
          }
        }
        etcd = {
          advertisedSubnets = [
            var.tenancy_1_vcn_cidr,
            module.tenancy_1_vcn.ipv6_cidr_block,
            var.tenancy_2_vcn_cidr,
            module.tenancy_2_vcn.ipv6_cidr_block,
          ]
          extraArgs = {
            listen-metrics-urls = "http://0.0.0.0:2381"
          }
        }
        proxy = {
          extraArgs = {
            metrics-bind-address = "0.0.0.0:10249"
          }
        }
        scheduler = {
          extraArgs = {
            bind-address = "0.0.0.0"
          }
        }
      }
    }),
    yamlencode({
      machine = {
        nodeLabels = {
          "node.kubernetes.io/exclude-from-external-load-balancers" = {
            "$patch" = "delete"
          }
        }
      }
    }),
    yamlencode({
      apiVersion = "v1alpha1"
      kind       = "UserVolumeConfig"
      name       = "local-path-provisioner"
      volumeType = "directory"
    }),
    yamlencode({
      apiVersion = "v1alpha1"
      kind       = "UserVolumeConfig"
      name       = "longhorn"
      volumeType = "directory"
    }),
  ]
}

data "talos_machine_configuration" "worker" {
  cluster_name       = var.cluster_name
  machine_type       = "worker"
  cluster_endpoint   = "https://${local.bootstrap_ip}:6443"
  machine_secrets    = talos_machine_secrets.cluster.machine_secrets
  talos_version      = local.cluster_versions.talos
  kubernetes_version = local.cluster_versions.kubernetes

  config_patches = [
    yamlencode({
      machine = {
        nodeLabels = {
          "node.longhorn.io/create-default-disk" = "true"
          "topology.cloudlab.io/location"        = "oci"
        }
        certSANs = local.cluster_api_addresses
        kernel = {
          modules = [
            { name = "binfmt_misc" },
          ]
        }
        sysctls = {
          "net.ipv4.ip_forward"          = "1"
          "net.ipv6.conf.all.forwarding" = "1"
        }
        time = {
          servers = ["169.254.169.254"]
        }
        kubelet = {
          extraArgs = {
            rotate-server-certificates = "true"
          }
          extraMounts = [
            {
              destination = "/var/lib/longhorn"
              source      = "/var/mnt/longhorn"
              type        = "bind"
              options     = ["bind", "rshared", "rw"]
            },
          ]
          nodeIP = {
            validSubnets = [
              var.tenancy_1_vcn_cidr,
              module.tenancy_1_vcn.ipv6_cidr_block,
              var.tenancy_2_vcn_cidr,
              module.tenancy_2_vcn.ipv6_cidr_block,
            ]
          }
        }
      }
      cluster = {
        network = {
          podSubnets     = var.kubernetes_pod_subnets
          serviceSubnets = var.kubernetes_service_subnets
        }
        proxy = {
          extraArgs = {
            metrics-bind-address = "0.0.0.0:10249"
          }
        }
      }
    }),
    yamlencode({
      apiVersion = "v1alpha1"
      kind       = "UserVolumeConfig"
      name       = "local-path-provisioner"
      volumeType = "directory"
    }),
    yamlencode({
      apiVersion = "v1alpha1"
      kind       = "UserVolumeConfig"
      name       = "longhorn"
      volumeType = "directory"
    }),
  ]
}

resource "random_pet" "node" {
  for_each = local.nodes

  length = 2
}

resource "oci_core_instance" "tenancy_1" {
  provider = oci.tenancy_1
  for_each = { for name, node in local.nodes : name => node if node.tenancy == 1 }

  depends_on = [oci_core_shape_management.talos_tenancy_1]

  availability_domain = data.oci_identity_availability_domains.tenancy_1.availability_domains[0].name
  compartment_id      = var.tenancy_1_compartment_ocid
  display_name        = "cloudlab-${random_pet.node[each.key].id}"
  shape               = var.node_defaults.shape
  metadata = {
    user_data = base64encode(
      each.value.role == "controlplane"
      ? data.talos_machine_configuration.control_plane.machine_configuration
      : data.talos_machine_configuration.worker.machine_configuration
    )
  }

  shape_config {
    ocpus         = var.node_defaults.ocpus
    memory_in_gbs = var.node_defaults.memory_in_gbs
  }

  create_vnic_details {
    assign_ipv6ip    = true
    assign_public_ip = "false"
    hostname_label   = random_pet.node[each.key].id
    private_ip       = each.value.ip
    subnet_id        = module.cross_tenancy_peering.tenancy_1_subnet_id

    ipv6address_ipv6subnet_cidr_pair_details {
      ipv6address     = each.value.ipv6
      ipv6subnet_cidr = each.value.ipv6_subnet_cidr
    }
  }

  source_details {
    source_type                     = "image"
    source_id                       = oci_core_image.talos_tenancy_1.id
    boot_volume_size_in_gbs         = tostring(var.node_defaults.boot_volume_size_in_gbs)
    boot_volume_vpus_per_gb         = tostring(var.node_defaults.boot_volume_vpus_per_gb)
    is_preserve_boot_volume_enabled = false
  }

  launch_options {
    boot_volume_type                    = "PARAVIRTUALIZED"
    firmware                            = "UEFI_64"
    is_consistent_volume_naming_enabled = true
    is_pv_encryption_in_transit_enabled = true
    network_type                        = "PARAVIRTUALIZED"
    remote_data_volume_type             = "PARAVIRTUALIZED"
  }

  lifecycle {
    ignore_changes = [metadata["user_data"], source_details]
  }
}

resource "oci_core_instance" "tenancy_2" {
  provider = oci.tenancy_2
  for_each = { for name, node in local.nodes : name => node if node.tenancy == 2 }

  depends_on = [oci_core_shape_management.talos_tenancy_2]

  availability_domain = data.oci_identity_availability_domains.tenancy_2.availability_domains[0].name
  compartment_id      = var.tenancy_2_compartment_ocid
  display_name        = "cloudlab-${random_pet.node[each.key].id}"
  shape               = var.node_defaults.shape
  metadata = {
    user_data = base64encode(
      each.value.role == "controlplane"
      ? data.talos_machine_configuration.control_plane.machine_configuration
      : data.talos_machine_configuration.worker.machine_configuration
    )
  }

  shape_config {
    ocpus         = var.node_defaults.ocpus
    memory_in_gbs = var.node_defaults.memory_in_gbs
  }

  create_vnic_details {
    assign_ipv6ip    = true
    assign_public_ip = "false"
    hostname_label   = random_pet.node[each.key].id
    private_ip       = each.value.ip
    subnet_id        = module.cross_tenancy_peering.tenancy_2_subnet_id

    ipv6address_ipv6subnet_cidr_pair_details {
      ipv6address     = each.value.ipv6
      ipv6subnet_cidr = each.value.ipv6_subnet_cidr
    }
  }

  source_details {
    source_type                     = "image"
    source_id                       = oci_core_image.talos_tenancy_2.id
    boot_volume_size_in_gbs         = tostring(var.node_defaults.boot_volume_size_in_gbs)
    boot_volume_vpus_per_gb         = tostring(var.node_defaults.boot_volume_vpus_per_gb)
    is_preserve_boot_volume_enabled = false
  }

  launch_options {
    boot_volume_type                    = "PARAVIRTUALIZED"
    firmware                            = "UEFI_64"
    is_consistent_volume_naming_enabled = true
    is_pv_encryption_in_transit_enabled = true
    network_type                        = "PARAVIRTUALIZED"
    remote_data_volume_type             = "PARAVIRTUALIZED"
  }

  lifecycle {
    ignore_changes = [metadata["user_data"], source_details]
  }
}
