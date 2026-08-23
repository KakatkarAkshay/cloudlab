resource "infisical_secret_folder" "observability" {
  project_id       = infisical_project.cloudlab.id
  environment_slug = var.infisical_environment_slug
  folder_path      = "/platform"
  name             = "observability"
}

resource "infisical_secret_folder" "oauth2_proxy" {
  project_id       = infisical_project.cloudlab.id
  environment_slug = var.infisical_environment_slug
  folder_path      = "/platform"
  name             = "oauth2-proxy"
}

resource "infisical_secret_folder" "authentik" {
  project_id       = infisical_project.cloudlab.id
  environment_slug = var.infisical_environment_slug
  folder_path      = "/platform"
  name             = "authentik"
  description      = "authentik server secret key and bootstrap credentials."
}

resource "infisical_secret_folder" "github_packages" {
  project_id       = infisical_project.cloudlab.id
  environment_slug = var.infisical_environment_slug
  folder_path      = "/platform"
  name             = "github-packages"
}

resource "infisical_secret_folder" "dns_credential_gateway" {
  project_id       = infisical_project.cloudlab.id
  environment_slug = var.infisical_environment_slug
  folder_path      = "/platform"
  name             = "dns-credential-gateway"
  description      = "Shared signing key for authenticated DoH and DoT device credentials."
}

resource "infisical_secret_folder" "apps" {
  project_id       = infisical_project.cloudlab.id
  environment_slug = var.infisical_environment_slug
  folder_path      = "/"
  name             = "apps"
}

resource "infisical_secret_folder" "codex_lb" {
  project_id       = infisical_project.cloudlab.id
  environment_slug = var.infisical_environment_slug
  folder_path      = infisical_secret_folder.apps.path
  name             = "codex-lb"
}

resource "infisical_secret" "idrive_access_key_id" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.idrive_credentials.path
  name         = "ACCESS_KEY_ID"
  value        = var.idrive_access_key_id
}

resource "infisical_secret" "idrive_secret_access_key" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.idrive_credentials.path
  name         = "ACCESS_SECRET_KEY"
  value        = var.idrive_secret_access_key
}

resource "infisical_secret" "idrive_e2_endpoint" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.idrive_credentials.path
  name         = "E2_ENDPOINT"
  value        = var.idrive_e2_endpoint
}

resource "infisical_secret" "loki_bucket" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.observability.path
  name         = "LOKI_BUCKET"
  value        = var.loki_bucket
}

resource "infisical_secret" "thanos_bucket" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.observability.path
  name         = "THANOS_BUCKET"
  value        = var.thanos_bucket
}

resource "infisical_secret" "oauth2_client_id" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.oauth2_proxy.path
  name         = "CLIENT_ID"
  value        = var.oauth2_client_id
}

resource "infisical_secret" "oauth2_client_secret" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.oauth2_proxy.path
  name         = "CLIENT_SECRET"
  value        = var.oauth2_client_secret
}

resource "random_bytes" "oauth2_proxy_cookie_secret" {
  length = 24
}

resource "infisical_secret" "oauth2_cookie_secret" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.oauth2_proxy.path
  name         = "COOKIE_SECRET"
  value        = random_bytes.oauth2_proxy_cookie_secret.base64
}

resource "random_bytes" "dns_credential_key" {
  length = 32
}

resource "infisical_secret" "dns_credential_key" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.dns_credential_gateway.path
  name         = "CREDENTIAL_KEY"
  value        = random_bytes.dns_credential_key.base64
}

resource "infisical_secret" "oauth2_restricted_user_access" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.oauth2_proxy.path
  name         = "RESTRICTED_USER_ACCESS"
  value        = var.oauth2_authorized_emails
}

resource "infisical_secret" "authentik_secret_key" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.authentik.path
  name         = "SECRET_KEY"
  value        = var.authentik_secret_key
}

resource "infisical_secret" "authentik_root_email" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.authentik.path
  name         = "ROOT_EMAIL"
  value        = var.authentik_root_email
}

resource "infisical_secret" "authentik_google_client_id" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.authentik.path
  name         = "GOOGLE_CLIENT_ID"
  value        = var.oauth2_client_id
}

resource "infisical_secret" "authentik_google_client_secret" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.authentik.path
  name         = "GOOGLE_CLIENT_SECRET"
  value        = var.oauth2_client_secret
}

resource "random_password" "immich_oauth_client_id" {
  length  = 32
  special = false
}

resource "random_password" "immich_oauth_client_secret" {
  length  = 64
  special = false
}

resource "infisical_secret" "authentik_immich_oauth_client_id" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.authentik.path
  name         = "IMMICH_OAUTH_CLIENT_ID"
  value        = random_password.immich_oauth_client_id.result
}

resource "infisical_secret" "authentik_immich_oauth_client_secret" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.authentik.path
  name         = "IMMICH_OAUTH_CLIENT_SECRET"
  value        = random_password.immich_oauth_client_secret.result
}

resource "random_password" "authentik_bootstrap_password" {
  length  = 32
  special = false
}

resource "infisical_secret" "authentik_bootstrap_password" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.authentik.path
  name         = "BOOTSTRAP_PASSWORD"
  value        = random_password.authentik_bootstrap_password.result
}

resource "random_password" "authentik_bootstrap_token" {
  length  = 60
  special = false
}

resource "infisical_secret" "authentik_bootstrap_token" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.authentik.path
  name         = "BOOTSTRAP_TOKEN"
  value        = random_password.authentik_bootstrap_token.result
}

resource "infisical_secret" "github_packages_username" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.github_packages.path
  name         = "USERNAME"
  value        = var.github_packages_username
}

resource "infisical_secret" "github_packages_token" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.github_packages.path
  name         = "TOKEN"
  value        = var.github_packages_token
}

resource "infisical_secret" "codex_lb_encryption_key" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.codex_lb.path
  name         = "ENCRYPTION_KEY"
  value        = var.codex_lb_encryption_key
}

resource "infisical_secret_folder" "headlamp" {
  project_id       = infisical_project.cloudlab.id
  environment_slug = var.infisical_environment_slug
  folder_path      = "/platform"
  name             = "headlamp"
  description      = "Kubeconfig for the homelab cluster, reached over the tailnet."
}

resource "infisical_secret" "headlamp_homelab_kubeconfig" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.headlamp.path
  name         = "HOMELAB_KUBECONFIG"
  value        = var.headlamp_homelab_kubeconfig
}

resource "infisical_secret_folder" "thanos" {
  project_id       = infisical_project.cloudlab.id
  environment_slug = var.infisical_environment_slug
  folder_path      = infisical_secret_folder.observability.path
  name             = "thanos"
}

resource "infisical_secret" "thanos_ca_cert" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.thanos.path
  name         = "CA_CERT"
  value        = tls_self_signed_cert.thanos_ca.cert_pem
}

resource "infisical_secret_folder" "loki" {
  project_id       = infisical_project.cloudlab.id
  environment_slug = var.infisical_environment_slug
  folder_path      = infisical_secret_folder.observability.path
  name             = "loki"
}

resource "infisical_secret" "loki_ca_cert" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.loki.path
  name         = "CA_CERT"
  value        = tls_self_signed_cert.loki_ca.cert_pem
}
