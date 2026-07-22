data "cloudflare_accounts" "current" {}

data "cloudflare_zone" "cloudlab" {
  filter = {
    name = var.cloudflare_zone
  }
}

locals {
  cloudflare_account_id = data.cloudflare_accounts.current.result[0].id
}

resource "cloudflare_zero_trust_tunnel_cloudflared" "cloudlab" {
  account_id = local.cloudflare_account_id
  name       = "CloudLab"
  config_src = "cloudflare"
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "cloudlab" {
  account_id = local.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.cloudlab.id
  source     = "cloudflare"

  config = {
    ingress = [
      {
        hostname = "*.${var.cloudflare_zone}"
        service  = "http://traefik.traefik.svc.cluster.local:80"
      },
      {
        service = "http_status:404"
      },
    ]
  }
}

data "cloudflare_zero_trust_tunnel_cloudflared_token" "cloudlab" {
  account_id = local.cloudflare_account_id
  tunnel_id  = cloudflare_zero_trust_tunnel_cloudflared.cloudlab.id
}

data "cloudflare_account_api_token_permission_groups_list" "zone_read" {
  account_id = local.cloudflare_account_id
  name       = "Zone Read"
  scope      = "com.cloudflare.api.account.zone"
}

data "cloudflare_account_api_token_permission_groups_list" "dns_write" {
  account_id = local.cloudflare_account_id
  name       = "DNS Write"
  scope      = "com.cloudflare.api.account.zone"
}

resource "cloudflare_account_token" "external_dns" {
  account_id = local.cloudflare_account_id
  name       = "cloudlab-external-dns"

  policies = [
    {
      effect = "allow"
      permission_groups = [
        { id = data.cloudflare_account_api_token_permission_groups_list.zone_read.result[0].id },
        { id = data.cloudflare_account_api_token_permission_groups_list.dns_write.result[0].id },
      ]
      resources = jsonencode({
        "com.cloudflare.api.account.zone.${data.cloudflare_zone.cloudlab.id}" = "*"
      })
    },
  ]
}
