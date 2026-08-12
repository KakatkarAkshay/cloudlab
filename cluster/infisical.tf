resource "kubernetes_secret_v1" "infisical_external_secrets_identity" {
  depends_on = [flux_bootstrap_git.cluster]

  metadata {
    name      = "infisical-kubernetes-auth"
    namespace = "flux-system"
  }

  data = {
    identityId = infisical_identity_kubernetes_auth.external_secrets.identity_id
  }
}

resource "infisical_identity_kubernetes_auth" "external_secrets" {
  depends_on = [flux_bootstrap_git.cluster]

  identity_id         = local.infra.infisical_external_secrets_identity_id
  token_reviewer_mode = "api"

  kubernetes_host           = "https://${local.infra.cluster_api_ip}:6443"
  kubernetes_ca_certificate = sensitive(trimspace(base64decode(talos_cluster_kubeconfig.cluster.kubernetes_client_configuration.ca_certificate)))

  allowed_namespaces            = ["external-secrets"]
  allowed_service_account_names = ["external-secrets"]

  access_token_ttl     = 3600
  access_token_max_ttl = 3600
}
