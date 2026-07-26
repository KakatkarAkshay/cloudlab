resource "tls_private_key" "flux_git" {
  algorithm = "ED25519"
}

resource "github_repository_deploy_key" "flux" {
  repository = var.github_repository
  title      = "flux-cloudlab-terraform"
  key        = trimspace(tls_private_key.flux_git.public_key_openssh)
  read_only  = false
}

# Tracks the Talos image identities from the infra stage. When the image
# (and therefore the nodes) is rebuilt, the cluster is re-bootstrapped.
resource "terraform_data" "talos_images" {
  input = [
    local.infra.talos_image_tenancy_1_id,
    local.infra.talos_image_tenancy_2_id,
  ]
}

resource "talos_machine_bootstrap" "cluster" {
  node                 = local.infra.control_plane_private_ip
  endpoint             = local.infra.cluster_api_ip
  client_configuration = local.infra.talos_client_configuration

  timeouts = {
    create = "15m"
  }

  lifecycle {
    replace_triggered_by = [terraform_data.talos_images]
  }
}

resource "talos_machine_configuration_apply" "control_plane" {
  depends_on = [talos_machine_bootstrap.cluster]

  node                        = local.infra.control_plane_private_ip
  endpoint                    = local.infra.cluster_api_ip
  client_configuration        = local.infra.talos_client_configuration
  machine_configuration_input = local.infra.machine_configuration_control_plane
  config_patches = [
    yamlencode({
      machine = {
        kubelet = {
          extraArgs = {
            provider-id = "oci://${local.infra.control_plane_instance_id}"
          }
        }
      }
    }),
  ]
}

resource "talos_machine_configuration_apply" "worker" {
  depends_on = [talos_machine_bootstrap.cluster]

  node                        = local.infra.worker_private_ip
  endpoint                    = local.infra.cluster_api_ip
  client_configuration        = local.infra.talos_client_configuration
  machine_configuration_input = local.infra.machine_configuration_worker
  config_patches = [
    yamlencode({
      machine = {
        kubelet = {
          extraArgs = {
            provider-id = "oci://${local.infra.worker_instance_id}"
          }
        }
      }
    }),
  ]
}

resource "talos_cluster_kubeconfig" "cluster" {
  depends_on = [
    talos_machine_configuration_apply.control_plane,
    talos_machine_configuration_apply.worker,
  ]

  node                 = local.infra.control_plane_private_ip
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
  path                   = "clusters/cloudlab"
  components_extra = [
    "image-automation-controller",
    "image-reflector-controller",
  ]

  lifecycle {
    replace_triggered_by = [terraform_data.talos_images]
  }
}
