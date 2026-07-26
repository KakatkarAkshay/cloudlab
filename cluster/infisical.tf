# Attaches Kubernetes auth to the external-secrets Infisical identity. Infisical
# reaches the API server to validate token reviews, so this must run in the
# cluster stage, once the control plane is up and reachable.
resource "infisical_identity_kubernetes_auth" "external_secrets" {
  identity_id         = local.infra.infisical_external_secrets_identity_id
  token_reviewer_mode = "api"

  kubernetes_host           = talos_cluster_kubeconfig.cluster.kubernetes_client_configuration.host
  kubernetes_ca_certificate = trimspace(base64decode(talos_cluster_kubeconfig.cluster.kubernetes_client_configuration.ca_certificate))

  allowed_namespaces            = ["external-secrets"]
  allowed_service_account_names = ["external-secrets"]

  access_token_ttl     = 3600
  access_token_max_ttl = 3600
}
