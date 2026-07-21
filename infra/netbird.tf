locals {
  netbird_nodes = {
    control-plane = "Triton"
    worker        = "Scorpion"
  }
  netbird_networks = {
    triton-vpc = {
      name = "Triton VPC"
      cidrs = [
        var.tenancy_1_vcn_cidr,
        module.tenancy_1_vcn.ipv6_cidr_block,
      ]
    }
    scorpion-vpc = {
      name = "Scorpion VPC"
      cidrs = [
        var.tenancy_2_vcn_cidr,
        module.tenancy_2_vcn.ipv6_cidr_block,
      ]
    }
    pod-network = {
      name  = "Pod Network"
      cidrs = var.kubernetes_pod_subnets
    }
    service-network = {
      name  = "Service Network"
      cidrs = var.kubernetes_service_subnets
    }
  }
  netbird_network_resources = merge([
    for network_key, network in local.netbird_networks : {
      for index, cidr in network.cidrs : "${network_key}-${index}" => {
        network_key = network_key
        name        = "${network.name} ${index == 0 ? "IPv4" : "IPv6"}"
        cidr        = cidr
      }
    }
  ]...)
}

resource "netbird_group" "oci" {
  name = "oci"
}

resource "netbird_group" "clients" {
  name = "cloudlab-clients"
}

resource "netbird_group" "resources" {
  name = "cloudlab-network-resources"
}

resource "netbird_setup_key" "node" {
  for_each = local.netbird_nodes

  name        = "CloudLab ${each.value}"
  type        = "reusable"
  auto_groups = [netbird_group.oci.id]
  ephemeral   = false
  revoked     = false
  usage_limit = 0
}

resource "netbird_network" "cloudlab" {
  for_each = local.netbird_networks

  name        = each.value.name
  description = "CloudLab ${each.value.name} routes"
}

resource "netbird_network_resource" "cloudlab" {
  for_each = local.netbird_network_resources

  network_id  = netbird_network.cloudlab[each.value.network_key].id
  name        = each.value.name
  description = "CloudLab ${each.value.name} CIDR"
  address     = each.value.cidr
  groups      = [netbird_group.resources.id]
  enabled     = true
}

resource "netbird_network_router" "oci" {
  for_each = local.netbird_networks

  network_id  = netbird_network.cloudlab[each.key].id
  peer_groups = [netbird_group.oci.id]
  metric      = 100
  enabled     = true
  masquerade  = true
}

resource "netbird_policy" "networks" {
  name        = "CloudLab network access"
  description = "Allow non-OCI CloudLab clients to reach routed networks"
  enabled     = true

  rule {
    name          = "CloudLab routed networks"
    action        = "accept"
    bidirectional = false
    enabled       = true
    protocol      = "all"
    sources       = [netbird_group.clients.id]
    destinations  = [netbird_group.resources.id]
  }
}

resource "netbird_policy" "oci_peers" {
  name        = "CloudLab OCI peer access"
  description = "Allow non-OCI CloudLab clients to reach OCI peers"
  enabled     = true

  rule {
    name          = "CloudLab OCI peers"
    action        = "accept"
    bidirectional = false
    enabled       = true
    protocol      = "all"
    sources       = [netbird_group.clients.id]
    destinations  = [netbird_group.oci.id]
  }
}
