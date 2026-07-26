resource "random_bytes" "oauth2_proxy_cookie_secret" {
  length = 24
}

resource "kubernetes_namespace_v1" "oauth2_proxy" {
  depends_on = [flux_bootstrap_git.cluster]

  metadata {
    name = "oauth2-proxy"
  }

  lifecycle {
    ignore_changes = [metadata[0].labels, metadata[0].annotations]
  }
}

resource "kubernetes_secret_v1" "oauth2_proxy_credentials" {
  metadata {
    name      = "oauth2-proxy-credentials"
    namespace = kubernetes_namespace_v1.oauth2_proxy.metadata[0].name
  }

  data = {
    "client-id"              = var.oauth2_client_id
    "client-secret"          = var.oauth2_client_secret
    "cookie-secret"          = random_bytes.oauth2_proxy_cookie_secret.base64
    "restricted-user-access" = var.oauth2_authorized_emails
  }
}
