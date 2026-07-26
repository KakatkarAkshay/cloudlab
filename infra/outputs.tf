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

output "tenancy_2_nlb_subnet_id" {
  description = "OCID of the acceptor public network load balancer subnet."
  value       = oci_core_subnet.nlb_tenancy_2.id
}

output "peering_status" {
  description = "Lifecycle state of the requestor LPG."
  value       = module.cross_tenancy_peering.peering_status
}

output "tenancy_1_vpn_tunnels" {
  description = "Tenancy 1 VPN endpoints and generated pre-shared keys for OpenWrt."
  value       = module.tenancy_1_site_to_site_vpn.tunnels
  sensitive   = true
}

output "tenancy_2_vpn_tunnels" {
  description = "Tenancy 2 VPN endpoints and generated pre-shared keys for OpenWrt."
  value       = module.tenancy_2_site_to_site_vpn.tunnels
  sensitive   = true
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

output "control_plane_ipv6" {
  description = "IPv6 address of the Talos control-plane node."
  value       = local.control_plane_ipv6
}

output "worker_private_ip" {
  description = "Private IP of the Talos worker node."
  value       = local.worker_ip
}

output "worker_ipv6" {
  description = "IPv6 address of the Talos worker node."
  value       = local.worker_ipv6
}

output "talos_schematic_id" {
  description = "Image Factory schematic ID used by the cluster."
  value       = talos_image_factory_schematic.cluster.id
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

# --- Consumed by the cluster stage via terraform_remote_state ---

output "cluster_api_ip" {
  description = "Public IPv4 the Kubernetes/Talos API is reached on (reserved NLB IP)."
  value       = local.cluster_api_ip
}

output "control_plane_instance_id" {
  description = "OCID of the control-plane instance (for the kubelet provider-id)."
  value       = oci_core_instance.control_plane.id
}

output "worker_instance_id" {
  description = "OCID of the worker instance (for the kubelet provider-id)."
  value       = oci_core_instance.worker.id
}

output "talos_client_configuration" {
  description = "Talos client configuration used to apply config, bootstrap and fetch kubeconfig."
  value       = talos_machine_secrets.cluster.client_configuration
  sensitive   = true
}

output "machine_configuration_control_plane" {
  description = "Rendered control-plane machine configuration."
  value       = data.talos_machine_configuration.control_plane.machine_configuration
  sensitive   = true
}

output "machine_configuration_worker" {
  description = "Rendered worker machine configuration."
  value       = data.talos_machine_configuration.worker.machine_configuration
  sensitive   = true
}

output "talos_image_tenancy_1_id" {
  description = "OCID of the control-plane Talos image (drives cluster re-bootstrap)."
  value       = oci_core_image.talos_tenancy_1.id
}

output "talos_image_tenancy_2_id" {
  description = "OCID of the worker Talos image (drives cluster re-bootstrap)."
  value       = oci_core_image.talos_tenancy_2.id
}

output "infisical_external_secrets_identity_id" {
  description = "Infisical identity ID for external-secrets; the cluster stage attaches k8s auth to it once the API server is reachable."
  value       = infisical_identity.external_secrets.id
}
