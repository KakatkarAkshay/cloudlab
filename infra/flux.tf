resource "flux_bootstrap_git" "cluster" {
  depends_on = [talos_cluster_kubeconfig.cluster]

  embedded_manifests     = true
  kustomization_override = file("${path.module}/flux-kustomization.yaml")
  path                   = "clusters/cloudlab"
  components_extra = [
    "image-automation-controller",
    "image-reflector-controller",
  ]
}
