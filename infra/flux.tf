resource "flux_bootstrap_git" "cluster" {
  depends_on = [talos_cluster_kubeconfig.cluster]

  embedded_manifests = true
  path               = "clusters/cloudlab"
  components_extra = [
    "image-automation-controller",
    "image-reflector-controller",
  ]
}
