locals {
  tailscale_nodes = {
    control-plane = "Triton"
    worker        = "Scorpion"
  }
  tailscale_advertised_routes = concat(
    var.kubernetes_pod_subnets,
    var.kubernetes_service_subnets,
    [
      var.tenancy_1_vcn_cidr,
      var.tenancy_2_vcn_cidr,
      module.tenancy_1_vcn.ipv6_cidr_block,
      module.tenancy_2_vcn.ipv6_cidr_block,
    ],
  )
}

resource "tailscale_tailnet_key" "node" {
  for_each = local.tailscale_nodes

  reusable            = false
  ephemeral           = true
  preauthorized       = true
  expiry              = 86400
  recreate_if_invalid = "never"
  tags                = ["tag:kubernetes-node"]
  description         = "Cloudlab ${each.value}"
}

resource "tailscale_acl" "cloudlab" {
  overwrite_existing_content = true

  acl = jsonencode({
    tagOwners = {
      "tag:kubernetes-node" = ["autogroup:admin"]
    }
    autoApprovers = {
      routes = {
        for cidr in local.tailscale_advertised_routes : cidr => ["tag:kubernetes-node"]
      }
    }
    grants = [
      {
        src = ["autogroup:member"]
        dst = concat(["tag:kubernetes-node"], local.tailscale_advertised_routes)
        ip  = ["*"]
      },
      {
        src = ["tag:kubernetes-node"]
        dst = ["tag:kubernetes-node"]
        ip  = ["*"]
      },
    ]
  })
}
