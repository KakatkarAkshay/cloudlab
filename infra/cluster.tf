locals {
  talos_image        = jsondecode(file("${path.module}/talos-image.json"))
  talos_image_object = "talos-${local.talos_image.version}-${local.talos_image.schematic_id}-oracle-arm64.oci"
  control_plane_ip   = cidrhost(var.tenancy_1_subnet_cidr, 10)
  worker_ip          = cidrhost(var.tenancy_2_subnet_cidr, 10)
  control_plane_ipv6 = cidrhost(cidrsubnet(module.tenancy_1_vcn.ipv6_cidr_block, 8, 0), 10)
  worker_ipv6        = cidrhost(cidrsubnet(module.tenancy_2_vcn.ipv6_cidr_block, 8, 0), 10)
  cluster_api_ip = one([
    for address in oci_network_load_balancer_network_load_balancer.control_plane.ip_addresses : address.ip_address
    if address.ip_version == "IPV4" && address.is_public
  ])
  cluster_api_addresses = [
    for address in oci_network_load_balancer_network_load_balancer.control_plane.ip_addresses : address.ip_address
    if address.is_public
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
  namespace      = var.tenancy_1_object_storage_namespace
  name           = "cloudlab-talos-images"
  access_type    = "NoPublicAccess"
}

resource "oci_objectstorage_bucket" "talos_tenancy_2" {
  provider = oci.tenancy_2

  compartment_id = var.tenancy_2_compartment_ocid
  namespace      = var.tenancy_2_object_storage_namespace
  name           = "cloudlab-talos-images"
  access_type    = "NoPublicAccess"
}

resource "oci_objectstorage_object" "talos_tenancy_1" {
  provider = oci.tenancy_1

  bucket    = oci_objectstorage_bucket.talos_tenancy_1.name
  namespace = var.tenancy_1_object_storage_namespace
  object    = local.talos_image_object
  source    = "${path.module}/build/talos-oracle-arm64.oci"

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [source]
  }
}

resource "oci_objectstorage_object" "talos_tenancy_2" {
  provider = oci.tenancy_2

  bucket    = oci_objectstorage_bucket.talos_tenancy_2.name
  namespace = var.tenancy_2_object_storage_namespace
  object    = local.talos_image_object
  source    = "${path.module}/build/talos-oracle-arm64.oci"

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [source]
  }
}

resource "oci_core_image" "talos_tenancy_1" {
  provider = oci.tenancy_1

  compartment_id = var.tenancy_1_compartment_ocid
  display_name   = "Talos ${local.talos_image.version} ARM64"
  launch_mode    = "PARAVIRTUALIZED"

  image_source_details {
    source_type              = "objectStorageTuple"
    namespace_name           = var.tenancy_1_object_storage_namespace
    bucket_name              = oci_objectstorage_bucket.talos_tenancy_1.name
    object_name              = oci_objectstorage_object.talos_tenancy_1.object
    operating_system         = "Talos"
    operating_system_version = trimprefix(local.talos_image.version, "v")
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "oci_core_image" "talos_tenancy_2" {
  provider = oci.tenancy_2

  compartment_id = var.tenancy_2_compartment_ocid
  display_name   = "Talos ${local.talos_image.version} ARM64"
  launch_mode    = "PARAVIRTUALIZED"

  image_source_details {
    source_type              = "objectStorageTuple"
    namespace_name           = var.tenancy_2_object_storage_namespace
    bucket_name              = oci_objectstorage_bucket.talos_tenancy_2.name
    object_name              = oci_objectstorage_object.talos_tenancy_2.object
    operating_system         = "Talos"
    operating_system_version = trimprefix(local.talos_image.version, "v")
  }

  lifecycle {
    create_before_destroy = true
  }
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
}

resource "oci_network_load_balancer_network_load_balancer" "control_plane" {
  provider = oci.tenancy_1

  compartment_id                 = var.tenancy_1_compartment_ocid
  display_name                   = "cloudlab-control-plane"
  subnet_id                      = oci_core_subnet.nlb.id
  is_private                     = false
  is_preserve_source_destination = false
  nlb_ip_version                 = "IPV4_AND_IPV6"
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

  backend_set_name         = oci_network_load_balancer_backend_set.kubernetes.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.control_plane.id
  ip_address               = local.control_plane_ip
  port                     = 6443
  name                     = "control-plane"
}

resource "oci_network_load_balancer_backend" "kubernetes_ipv6" {
  provider = oci.tenancy_1

  backend_set_name         = oci_network_load_balancer_backend_set.kubernetes_ipv6.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.control_plane.id
  ip_address               = local.control_plane_ipv6
  port                     = 6443
  name                     = "control-plane-kubernetes-ipv6"
}

resource "oci_network_load_balancer_backend" "talos" {
  provider = oci.tenancy_1

  backend_set_name         = oci_network_load_balancer_backend_set.talos.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.control_plane.id
  ip_address               = local.control_plane_ip
  port                     = 50000
  name                     = "control-plane-talos"
}

resource "oci_network_load_balancer_backend" "talos_ipv6" {
  provider = oci.tenancy_1

  backend_set_name         = oci_network_load_balancer_backend_set.talos_ipv6.name
  network_load_balancer_id = oci_network_load_balancer_network_load_balancer.control_plane.id
  ip_address               = local.control_plane_ipv6
  port                     = 50000
  name                     = "control-plane-talos-ipv6"
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
  talos_version = local.talos_image.version
}

data "talos_machine_configuration" "control_plane" {
  cluster_name     = var.cluster_name
  machine_type     = "controlplane"
  cluster_endpoint = "https://${local.cluster_api_ip}:6443"
  machine_secrets  = talos_machine_secrets.cluster.machine_secrets
  talos_version    = local.talos_image.version

  config_patches = [
    yamlencode({
      machine = {
        certSANs = local.cluster_api_addresses
        sysctls = {
          "net.ipv4.ip_forward"          = "1"
          "net.ipv6.conf.all.forwarding" = "1"
        }
        time = {
          servers = ["169.254.169.254"]
        }
        kubelet = {
          nodeIP = {
            validSubnets = [var.tenancy_1_vcn_cidr, module.tenancy_1_vcn.ipv6_cidr_block]
          }
        }
      }
      cluster = {
        network = {
          podSubnets     = var.kubernetes_pod_subnets
          serviceSubnets = var.kubernetes_service_subnets
        }
        apiServer = {
          certSANs = local.cluster_api_addresses
        }
        etcd = {
          advertisedSubnets = [var.tenancy_1_vcn_cidr, module.tenancy_1_vcn.ipv6_cidr_block]
        }
      }
    }),
    yamlencode({
      apiVersion = "v1alpha1"
      kind       = "ExtensionServiceConfig"
      name       = "tailscale"
      environment = [
        "TS_AUTHKEY=${tailscale_tailnet_key.node["control-plane"].key}",
        "TS_HOSTNAME=Triton",
        "TS_AUTH_ONCE=true",
        "TS_ROUTES=${join(",", local.tailscale_advertised_routes)}",
      ]
    }),
  ]
}

data "talos_machine_configuration" "worker" {
  cluster_name     = var.cluster_name
  machine_type     = "worker"
  cluster_endpoint = "https://${local.cluster_api_ip}:6443"
  machine_secrets  = talos_machine_secrets.cluster.machine_secrets
  talos_version    = local.talos_image.version

  config_patches = [
    yamlencode({
      machine = {
        certSANs = local.cluster_api_addresses
        sysctls = {
          "net.ipv4.ip_forward"          = "1"
          "net.ipv6.conf.all.forwarding" = "1"
        }
        time = {
          servers = ["169.254.169.254"]
        }
        kubelet = {
          nodeIP = {
            validSubnets = [var.tenancy_2_vcn_cidr, module.tenancy_2_vcn.ipv6_cidr_block]
          }
        }
      }
      cluster = {
        network = {
          podSubnets     = var.kubernetes_pod_subnets
          serviceSubnets = var.kubernetes_service_subnets
        }
      }
    }),
    yamlencode({
      apiVersion = "v1alpha1"
      kind       = "ExtensionServiceConfig"
      name       = "tailscale"
      environment = [
        "TS_AUTHKEY=${tailscale_tailnet_key.node["worker"].key}",
        "TS_HOSTNAME=Scorpion",
        "TS_AUTH_ONCE=true",
        "TS_ROUTES=${join(",", local.tailscale_advertised_routes)}",
      ]
    }),
  ]
}

resource "oci_core_instance" "control_plane" {
  provider = oci.tenancy_1

  availability_domain = data.oci_identity_availability_domains.tenancy_1.availability_domains[0].name
  compartment_id      = var.tenancy_1_compartment_ocid
  display_name        = "cloudlab-control-plane"
  shape               = "VM.Standard.A1.Flex"
  metadata = {
    user_data = base64encode(data.talos_machine_configuration.control_plane.machine_configuration)
  }

  shape_config {
    ocpus         = 2
    memory_in_gbs = 12
  }

  create_vnic_details {
    assign_ipv6ip    = true
    assign_public_ip = "false"
    hostname_label   = "control-plane"
    private_ip       = local.control_plane_ip
    subnet_id        = module.cross_tenancy_peering.tenancy_1_subnet_id

    ipv6address_ipv6subnet_cidr_pair_details {
      ipv6address     = local.control_plane_ipv6
      ipv6subnet_cidr = cidrsubnet(module.tenancy_1_vcn.ipv6_cidr_block, 8, 0)
    }
  }

  source_details {
    source_type                     = "image"
    source_id                       = oci_core_image.talos_tenancy_1.id
    boot_volume_size_in_gbs         = "200"
    boot_volume_vpus_per_gb         = "120"
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
    ignore_changes = [metadata["user_data"]]
  }
}

resource "oci_core_instance" "worker" {
  provider = oci.tenancy_2

  availability_domain = data.oci_identity_availability_domains.tenancy_2.availability_domains[0].name
  compartment_id      = var.tenancy_2_compartment_ocid
  display_name        = "cloudlab-worker"
  shape               = "VM.Standard.A1.Flex"
  metadata = {
    user_data = base64encode(data.talos_machine_configuration.worker.machine_configuration)
  }

  shape_config {
    ocpus         = 2
    memory_in_gbs = 12
  }

  create_vnic_details {
    assign_ipv6ip    = true
    assign_public_ip = "false"
    hostname_label   = "worker"
    private_ip       = local.worker_ip
    subnet_id        = module.cross_tenancy_peering.tenancy_2_subnet_id

    ipv6address_ipv6subnet_cidr_pair_details {
      ipv6address     = local.worker_ipv6
      ipv6subnet_cidr = cidrsubnet(module.tenancy_2_vcn.ipv6_cidr_block, 8, 0)
    }
  }

  source_details {
    source_type                     = "image"
    source_id                       = oci_core_image.talos_tenancy_2.id
    boot_volume_size_in_gbs         = "200"
    boot_volume_vpus_per_gb         = "120"
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
    ignore_changes = [metadata["user_data"]]
  }
}

resource "talos_machine_bootstrap" "cluster" {
  depends_on = [
    oci_core_instance.control_plane,
    oci_core_instance.worker,
    oci_network_load_balancer_backend.talos,
    oci_network_load_balancer_listener.talos,
  ]

  node                 = local.control_plane_ip
  endpoint             = local.cluster_api_ip
  client_configuration = talos_machine_secrets.cluster.client_configuration

  timeouts = {
    create = "15m"
  }
}

resource "talos_machine_configuration_apply" "control_plane" {
  depends_on = [talos_machine_bootstrap.cluster]

  node                        = local.control_plane_ip
  endpoint                    = local.cluster_api_ip
  client_configuration        = talos_machine_secrets.cluster.client_configuration
  machine_configuration_input = data.talos_machine_configuration.control_plane.machine_configuration
}

resource "talos_machine_configuration_apply" "worker" {
  depends_on = [talos_machine_bootstrap.cluster]

  node                        = local.worker_ip
  endpoint                    = local.cluster_api_ip
  client_configuration        = talos_machine_secrets.cluster.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
}

resource "talos_cluster_kubeconfig" "cluster" {
  depends_on = [
    talos_machine_configuration_apply.control_plane,
    talos_machine_configuration_apply.worker,
  ]

  node                 = local.control_plane_ip
  endpoint             = local.cluster_api_ip
  client_configuration = talos_machine_secrets.cluster.client_configuration

  timeouts = {
    create = "10m"
  }
}
