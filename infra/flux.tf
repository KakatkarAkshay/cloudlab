resource "flux_bootstrap_git" "cluster" {
  depends_on = [talos_cluster_kubeconfig.cluster]

  embedded_manifests = true
  path               = "clusters/cloudlab"
  components_extra = [
    "image-automation-controller",
    "image-reflector-controller",
  ]
}

resource "kubernetes_secret_v1" "sops_age" {
  depends_on = [flux_bootstrap_git.cluster]

  metadata {
    name      = "sops-age"
    namespace = "flux-system"
  }

  data_wo = {
    "age.agekey" = var.sops_age_key
  }
  data_wo_revision = var.sops_age_key_revision
}
