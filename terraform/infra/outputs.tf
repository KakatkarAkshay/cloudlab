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

output "control_plane_endpoint" {
  description = "Public Kubernetes API endpoint."
  value       = "https://${local.cluster_api_ip}:6443"
}

output "control_plane_endpoints" {
  description = "Public IPv4 and IPv6 addresses assigned to the control-plane NLB."
  value       = local.cluster_api_addresses
}

output "nodes" {
  description = "Cluster nodes keyed by slot, with the generated hostname, addressing and instance OCID."
  value = {
    for name, node in local.nodes : name => {
      hostname    = random_pet.node[name].id
      role        = node.role
      tenancy     = node.tenancy
      private_ip  = node.ip
      ipv6        = node.ipv6
      instance_id = merge(oci_core_instance.tenancy_1, oci_core_instance.tenancy_2)[name].id
    }
  }
}

output "bootstrap_node_private_ip" {
  description = "Private IP of the node the cluster stage bootstraps Talos against."
  value       = local.bootstrap_ip
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
        nodes     = [for node in local.nodes : node.ip]
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

output "cloudflare_api_token" {
  description = "External-DNS Cloudflare API token, consumed by the homelab cluster so both share one token."
  value       = cloudflare_account_token.external_dns.value
  sensitive   = true
}

output "idrive_access_key_id" {
  description = "iDrive E2 access key ID, shared with the homelab cluster."
  value       = var.idrive_access_key_id
  sensitive   = true
}

output "idrive_secret_access_key" {
  description = "iDrive E2 secret access key, shared with the homelab cluster."
  value       = var.idrive_secret_access_key
  sensitive   = true
}

output "idrive_e2_endpoint" {
  description = "iDrive E2 endpoint URL, shared with the homelab cluster."
  value       = var.idrive_e2_endpoint
}

output "idrive_aws_region" {
  description = "AWS-compatible region for the iDrive E2 credentials, shared with the homelab cluster."
  value       = var.idrive_aws_region
}

output "volsync_restic_password" {
  description = "VolSync restic repository password; must match across clusters or backups become unreadable."
  value       = var.volsync_restic_password
  sensitive   = true
}

output "immich_oauth_client_id" {
  description = "OAuth client ID shared by Authentik and the homelab Immich deployment."
  value       = random_password.immich_oauth_client_id.result
  sensitive   = true
}

output "immich_oauth_client_secret" {
  description = "OAuth client secret shared by Authentik and the homelab Immich deployment."
  value       = random_password.immich_oauth_client_secret.result
  sensitive   = true
}



output "thanos_ca_cert" {
  description = "CA certificate that clients writing to Thanos are issued from."
  value       = tls_self_signed_cert.thanos_ca.cert_pem
}

output "thanos_ca_key" {
  description = "CA private key that clients writing to Thanos are issued from."
  value       = tls_private_key.thanos_ca.private_key_pem
  sensitive   = true
}

output "loki_ca_cert" {
  description = "CA certificate that clients writing to Loki are issued from."
  value       = tls_self_signed_cert.loki_ca.cert_pem
}

output "loki_ca_key" {
  description = "CA private key that clients writing to Loki are issued from."
  value       = tls_private_key.loki_ca.private_key_pem
  sensitive   = true
}
