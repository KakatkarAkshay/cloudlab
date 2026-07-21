# Keep the prior addresses for one apply so Helm uninstalls before bootstrap.
resource "helm_release" "flux" {
  count = 0

  name       = "flux"
  repository = "oci://ghcr.io/fluxcd-community/charts"
  chart      = "flux2"
  version    = "2.19.0"
  namespace  = "flux-system"
}

resource "helm_release" "flux_sync" {
  count = 0

  name       = "flux-system"
  repository = "oci://ghcr.io/fluxcd-community/charts"
  chart      = "flux2-sync"
  version    = "1.15.0"
  namespace  = "flux-system"

  depends_on = [helm_release.flux]
}

resource "flux_bootstrap_git" "cluster" {
  depends_on = [
    helm_release.flux,
    helm_release.flux_sync,
    talos_cluster_kubeconfig.cluster,
  ]

  embedded_manifests = true
  path               = "clusters/cloudlab"
  components_extra = [
    "image-automation-controller",
    "image-reflector-controller",
  ]
}
