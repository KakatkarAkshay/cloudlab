resource "infisical_project" "cloudlab" {
  name = "CloudLab"
  slug = "cloudlab"
}

resource "infisical_identity" "terraform" {
  name   = "Terraform"
  org_id = var.infisical_org_id
  role   = "admin"
}

resource "infisical_project_identity" "terraform" {
  project_id     = infisical_project.cloudlab.id
  identity_id    = infisical_identity.terraform.id
  adopt_existing = true

  roles = [
    { role_slug = "admin" },
  ]
}

resource "infisical_identity" "external_secrets" {
  name                  = "cloudlab-eso"
  org_id                = var.infisical_org_id
  role                  = "no-access"
  has_delete_protection = true
}

resource "infisical_identity_kubernetes_auth" "external_secrets" {
  identity_id         = infisical_identity.external_secrets.id
  token_reviewer_mode = "api"

  kubernetes_host           = talos_cluster_kubeconfig.cluster.kubernetes_client_configuration.host
  kubernetes_ca_certificate = trimspace(base64decode(talos_cluster_kubeconfig.cluster.kubernetes_client_configuration.ca_certificate))

  allowed_namespaces            = ["external-secrets"]
  allowed_service_account_names = ["external-secrets"]

  access_token_ttl     = 3600
  access_token_max_ttl = 3600
}

resource "infisical_project_identity" "external_secrets" {
  project_id     = infisical_project.cloudlab.id
  identity_id    = infisical_identity.external_secrets.id
  adopt_existing = true

  roles = [
    { role_slug = "viewer" },
  ]
}

resource "infisical_secret" "cloudflare_api_token" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = "prod"
  folder_path  = "/platform/cloudflare"
  name         = "API_TOKEN"
  value        = cloudflare_account_token.external_dns.value
}

resource "infisical_secret" "cloudflare_tunnel_token" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = "prod"
  folder_path  = "/platform/cloudflare"
  name         = "TUNNEL_TOKEN"
  value        = data.cloudflare_zero_trust_tunnel_cloudflared_token.cloudlab.token
}

ephemeral "random_bytes" "oauth2_proxy_cookie_secret" {
  length = 32
}

resource "infisical_secret" "oauth2_proxy_cookie_secret" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = "prod"
  folder_path  = "/platform/oauth2-proxy"
  name         = "COOKIE_SECRET"

  # Write-only: never stored in Terraform state. Bump the version to rotate.
  value_wo         = ephemeral.random_bytes.oauth2_proxy_cookie_secret.base64
  value_wo_version = 1
}

resource "infisical_secret" "postgres_backup_aws_region" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = "prod"
  folder_path  = "/platform/postgres-backup"
  name         = "AWS_REGION"
  value        = var.postgres_backup_aws_region
}
