resource "tls_private_key" "flux_git" {
  algorithm = "ED25519"
}

resource "github_repository_deploy_key" "flux" {
  repository = var.github_repository
  title      = "flux-cloudlab-terraform"
  key        = trimspace(tls_private_key.flux_git.public_key_openssh)
  read_only  = false
}

resource "talos_machine_bootstrap" "cluster" {
  node                 = local.infra.bootstrap_node_private_ip
  endpoint             = local.infra.cluster_api_ip
  client_configuration = local.infra.talos_client_configuration

  timeouts = {
    create = "15m"
  }
}

resource "talos_machine_configuration_apply" "node" {
  depends_on = [talos_machine_bootstrap.cluster]
  for_each   = local.infra.nodes

  node                 = each.value.private_ip
  endpoint             = local.infra.cluster_api_ip
  client_configuration = local.infra.talos_client_configuration
  machine_configuration_input = (
    each.value.role == "controlplane"
    ? local.infra.machine_configuration_control_plane
    : local.infra.machine_configuration_worker
  )
  config_patches = [
    yamlencode({
      machine = {
        kubelet = {
          extraArgs = {
            provider-id = "oci://${each.value.instance_id}"
          }
        }
      }
    }),
  ]
}

resource "talos_cluster_kubeconfig" "cluster" {
  depends_on = [talos_machine_configuration_apply.node]

  node                 = local.infra.bootstrap_node_private_ip
  endpoint             = local.infra.cluster_api_ip
  client_configuration = local.infra.talos_client_configuration

  timeouts = {
    create = "15m"
  }
}

resource "flux_bootstrap_git" "cluster" {
  depends_on = [talos_cluster_kubeconfig.cluster]

  embedded_manifests     = true
  kustomization_override = file("${path.module}/flux-kustomization.yaml")
  path                   = "kubernetes/clusters/cloudlab"
  components_extra = [
    "image-automation-controller",
    "image-reflector-controller",
  ]
}
