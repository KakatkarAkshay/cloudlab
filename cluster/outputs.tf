output "kubeconfig" {
  description = "Administrative kubeconfig for the Talos cluster."
  value       = talos_cluster_kubeconfig.cluster.kubeconfig_raw
  sensitive   = true
}

output "talosconfig" {
  description = "Talos client configuration for cluster administration."
  value = yamlencode({
    context = "cloudlab"
    contexts = {
      cloudlab = {
        endpoints = [local.infra.cluster_api_ip]
        nodes     = [local.infra.control_plane_private_ip, local.infra.worker_private_ip]
        ca        = local.infra.talos_client_configuration.ca_certificate
        crt       = local.infra.talos_client_configuration.client_certificate
        key       = local.infra.talos_client_configuration.client_key
      }
    }
  })
  sensitive = true
}
