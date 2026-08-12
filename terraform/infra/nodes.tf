locals {
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
}

data "oci_identity_availability_domains" "tenancy_1" {
  provider = oci.tenancy_1

  compartment_id = var.tenancy_1_compartment_ocid
}

data "oci_identity_availability_domains" "tenancy_2" {
  provider = oci.tenancy_2

  compartment_id = var.tenancy_2_compartment_ocid
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

  # OCI stores in-transit encryption on the boot volume attachment but reports
  # it false here, so the attribute never converges.
  lifecycle {
    ignore_changes = [
      metadata["user_data"],
      source_details,
      launch_options[0].is_pv_encryption_in_transit_enabled,
    ]
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

  # OCI stores in-transit encryption on the boot volume attachment but reports
  # it false here, so the attribute never converges.
  lifecycle {
    ignore_changes = [
      metadata["user_data"],
      source_details,
      launch_options[0].is_pv_encryption_in_transit_enabled,
    ]
  }
}
