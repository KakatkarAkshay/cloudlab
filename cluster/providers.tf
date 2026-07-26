provider "flux" {
  kubernetes = {
    host                   = talos_cluster_kubeconfig.cluster.kubernetes_client_configuration.host
    cluster_ca_certificate = base64decode(talos_cluster_kubeconfig.cluster.kubernetes_client_configuration.ca_certificate)
    client_certificate     = base64decode(talos_cluster_kubeconfig.cluster.kubernetes_client_configuration.client_certificate)
    client_key             = base64decode(talos_cluster_kubeconfig.cluster.kubernetes_client_configuration.client_key)
  }

  git = {
    url    = "ssh://git@github.com/${var.github_owner}/${var.github_repository}.git"
    branch = "main"
    ssh = {
      username    = "git"
      private_key = tls_private_key.flux_git.private_key_openssh
    }
  }
}

# Reads GITHUB_TOKEN from the environment.
provider "github" {
  owner = var.github_owner
}

# Uses OIDC in CI and Universal Auth for local administration.
provider "infisical" {
  host = var.infisical_host
  auth = {
    oidc      = var.infisical_auth_method == "oidc" ? {} : null
    universal = var.infisical_auth_method == "universal" ? {} : null
  }
}
