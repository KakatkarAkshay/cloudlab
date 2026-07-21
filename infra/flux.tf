locals {
  flux_namespace = "flux-system"
}

resource "helm_release" "flux" {
  name             = "flux"
  repository       = "oci://ghcr.io/fluxcd-community/charts"
  chart            = "flux2"
  version          = "2.19.0"
  namespace        = local.flux_namespace
  create_namespace = true
  atomic           = true
  wait             = true
  timeout          = 600

  depends_on = [talos_cluster_kubeconfig.cluster]
}

resource "helm_release" "flux_sync" {
  name       = "flux-system"
  repository = "oci://ghcr.io/fluxcd-community/charts"
  chart      = "flux2-sync"
  version    = "1.15.0"
  namespace  = local.flux_namespace
  atomic     = true
  wait       = true
  timeout    = 300

  values = [yamlencode({
    secret = {
      create = true
      data = {
        "identity.pub" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIM8FAhyM3aKIoYoQxsVl0Hw1LTM8z2jZdmLxR737UguN flux-cloudlab"
        known_hosts    = "github.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl"
      }
    }
    gitRepository = {
      spec = {
        url      = "ssh://git@github.com/abyssal-labs/cloudlab.git"
        interval = "1m"
        ref = {
          branch = "main"
        }
      }
    }
    kustomization = {
      spec = {
        interval = "1m"
        path     = "./"
        prune    = true
        timeout  = "5m"
        wait     = true
      }
    }
  })]

  set_wo = [{
    name  = "secret.data.identity"
    value = var.flux_git_ssh_private_key
  }]
  set_wo_revision = 1

  depends_on = [helm_release.flux]
}
