output "tenancy_1_vcn_id" {
  description = "OCID of the requestor VCN."
  value       = module.tenancy_1_vcn.id
}

output "tenancy_1_subnet_id" {
  description = "OCID of the requestor private subnet."
  value       = module.cross_tenancy_peering.tenancy_1_subnet_id
}

output "tenancy_2_vcn_id" {
  description = "OCID of the acceptor VCN."
  value       = module.tenancy_2_vcn.id
}

output "tenancy_2_subnet_id" {
  description = "OCID of the acceptor private subnet."
  value       = module.cross_tenancy_peering.tenancy_2_subnet_id
}

output "peering_status" {
  description = "Lifecycle state of the requestor LPG."
  value       = module.cross_tenancy_peering.peering_status
}

output "control_plane_endpoint" {
  description = "Public Kubernetes API endpoint."
  value       = "https://${local.cluster_api_ip}:6443"
}

output "control_plane_endpoints" {
  description = "Public IPv4 and IPv6 addresses assigned to the control-plane NLB."
  value       = local.cluster_api_addresses
}

output "control_plane_private_ip" {
  description = "Private IP of the Talos control-plane node."
  value       = local.control_plane_ip
}

output "worker_private_ip" {
  description = "Private IP of the Talos worker node."
  value       = local.worker_ip
}

output "talosconfig" {
  description = "Talos client configuration for cluster administration."
  value = yamlencode({
    context = var.cluster_name
    contexts = {
      (var.cluster_name) = {
        endpoints = [local.cluster_api_ip]
        nodes     = [local.control_plane_ip, local.worker_ip]
        ca        = talos_machine_secrets.cluster.client_configuration.ca_certificate
        crt       = talos_machine_secrets.cluster.client_configuration.client_certificate
        key       = talos_machine_secrets.cluster.client_configuration.client_key
      }
    }
  })
  sensitive = true
}

output "kubeconfig" {
  description = "Administrative kubeconfig for the Talos cluster."
  value       = talos_cluster_kubeconfig.cluster.kubeconfig_raw
  sensitive   = true
}
