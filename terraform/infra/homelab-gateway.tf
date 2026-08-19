resource "cloudflare_dns_record" "homelab_gateway" {
  zone_id = data.cloudflare_zone.cloudlab.id
  name    = "homelab-gateway.${var.cloudflare_zone}"
  type    = "A"
  content = var.homelab_public_ip
  ttl     = 1
  proxied = true
}
