resource "helm_release" "flannel" {
  name             = "flannel"
  repository       = "https://flannel-io.github.io/flannel/"
  chart            = "flannel"
  namespace        = "kube-flannel"
  create_namespace = true

  set = [{
    name  = "podCidr"
    value = "10.244.0.0/16"
  }]
}
