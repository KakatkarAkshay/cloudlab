variable "oci_region" {
  description = "OCI region used by both tenancies. Local peering requires both VCNs to be in the same region."
  type        = string
}

variable "oci_fingerprint" {
  description = "Fingerprint of the shared OCI API signing key."
  type        = string
}

variable "oci_private_key" {
  description = "PEM-encoded private key shared by the two OCI users."
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "tenancy_1_ocid" {
  description = "OCID of the requestor tenancy."
  type        = string
}

variable "tenancy_1_user_ocid" {
  description = "OCID of the OCI user in the requestor tenancy."
  type        = string
}

variable "tenancy_1_compartment_ocid" {
  description = "Compartment OCID in the requestor tenancy where networking resources are created."
  type        = string
}

variable "tenancy_2_ocid" {
  description = "OCID of the acceptor tenancy."
  type        = string
}

variable "tenancy_2_user_ocid" {
  description = "OCID of the OCI user in the acceptor tenancy."
  type        = string
}

variable "tenancy_2_compartment_ocid" {
  description = "Compartment OCID in the acceptor tenancy where networking resources are created."
  type        = string
}

variable "requestor_group_name" {
  description = "Name of the tenancy 1 IAM group authorized to connect the LPGs, for example Administrators."
  type        = string
}

variable "infisical_org_id" {
  description = "Infisical organization ID that owns the CloudLab project."
  type        = string
}

variable "infisical_environment_slug" {
  description = "Infisical environment secrets and folders are written to."
  type        = string
  default     = "prod"
}

variable "infisical_host" {
  description = "Base URL of the Infisical instance."
  type        = string
  default     = "https://app.infisical.com"
}

variable "infisical_auth_method" {
  description = "Infisical machine identity authentication method. CI uses OIDC; local runs may use Universal Auth."
  type        = string
  default     = "oidc"

  validation {
    condition     = contains(["oidc", "universal"], var.infisical_auth_method)
    error_message = "infisical_auth_method must be either oidc or universal."
  }
}

variable "oauth2_client_id" {
  description = "Google OAuth client ID shared by oauth2-proxy and Grafana."
  type        = string
  sensitive   = true
}

variable "oauth2_client_secret" {
  description = "Google OAuth client secret shared by oauth2-proxy and Grafana."
  type        = string
  sensitive   = true
}

variable "oauth2_authorized_emails" {
  description = "Newline/comma-separated emails allowed through oauth2-proxy."
  type        = string
  sensitive   = true
}

variable "cloudflare_zone" {
  description = "Cloudflare DNS zone served by the cluster."
  type        = string
}

variable "idrive_aws_region" {
  description = "AWS-compatible region used by the shared iDrive E2 credentials."
  type        = string
}

variable "idrive_access_key_id" {
  description = "iDrive E2 S3 access key ID."
  type        = string
  sensitive   = true
}

variable "idrive_secret_access_key" {
  description = "iDrive E2 S3 secret access key."
  type        = string
  sensitive   = true
}

variable "idrive_e2_endpoint" {
  description = "iDrive E2 S3 endpoint URL."
  type        = string
}

variable "loki_bucket" {
  description = "iDrive E2 bucket for Loki storage."
  type        = string
}

variable "thanos_bucket" {
  description = "iDrive E2 bucket for Thanos object storage."
  type        = string
}

variable "github_packages_username" {
  description = "Username for GHCR image pulls (any value with a valid PAT)."
  type        = string
  default     = "cloudlab"
}

variable "github_packages_token" {
  description = "GHCR read PAT for image pulls."
  type        = string
  sensitive   = true
}

variable "github_runner_app_id" {
  description = "GitHub App ID for the Actions Runner Controller."
  type        = string
  sensitive   = true
}

variable "github_runner_app_installation_id" {
  description = "GitHub App installation ID for the Actions Runner Controller."
  type        = string
  sensitive   = true
}

variable "github_runner_app_private_key" {
  description = "GitHub App private key (PEM) for the Actions Runner Controller."
  type        = string
  sensitive   = true
}

variable "codex_lb_encryption_key" {
  description = "Fernet key used by codex-lb to encrypt application data."
  type        = string
  sensitive   = true
}

variable "authentik_secret_key" {
  description = "authentik secret key. Must outlive the cluster and Terraform state, or encrypted columns in a restored authentik database become unreadable."
  type        = string
  sensitive   = true
}

variable "volsync_restic_password" {
  description = "Encryption key for the VolSync restic repositories; losing it makes every backup unrecoverable."
  type        = string
  sensitive   = true
}

variable "github_owner" {
  description = "GitHub account that owns the CloudLab repository."
  type        = string
}

variable "github_repository" {
  description = "Name of the CloudLab GitHub repository."
  type        = string
}

variable "cluster_name" {
  description = "Talos and Kubernetes cluster name."
  type        = string
  default     = "cloudlab"
}

variable "kubernetes_pod_subnets" {
  description = "IPv4 and IPv6 CIDRs assigned to Kubernetes pods."
  type        = list(string)
  default     = ["10.244.0.0/16", "fd00:10:244::/56"]

  validation {
    condition     = length(var.kubernetes_pod_subnets) == 2 && alltrue([for cidr in var.kubernetes_pod_subnets : can(cidrhost(cidr, 0))])
    error_message = "kubernetes_pod_subnets must contain valid IPv4 and IPv6 CIDRs."
  }
}

variable "kubernetes_service_subnets" {
  description = "IPv4 and IPv6 CIDRs assigned to Kubernetes services."
  type        = list(string)
  default     = ["10.96.0.0/20", "fd00:10:96::/112"]

  validation {
    condition     = length(var.kubernetes_service_subnets) == 2 && alltrue([for cidr in var.kubernetes_service_subnets : can(cidrhost(cidr, 0))])
    error_message = "kubernetes_service_subnets must contain valid IPv4 and IPv6 CIDRs."
  }
}

variable "tenancy_1_vcn_cidr" {
  description = "IPv4 CIDR for the requestor VCN."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.tenancy_1_vcn_cidr, 0))
    error_message = "tenancy_1_vcn_cidr must be a valid IPv4 CIDR."
  }
}

variable "tenancy_1_subnet_cidr" {
  description = "IPv4 CIDR for the requestor private subnet."
  type        = string
  default     = "10.0.0.0/24"

  validation {
    condition     = can(cidrhost(var.tenancy_1_subnet_cidr, 0))
    error_message = "tenancy_1_subnet_cidr must be a valid IPv4 CIDR."
  }
}

variable "tenancy_2_vcn_cidr" {
  description = "IPv4 CIDR for the acceptor VCN."
  type        = string
  default     = "10.1.0.0/16"

  validation {
    condition     = can(cidrhost(var.tenancy_2_vcn_cidr, 0))
    error_message = "tenancy_2_vcn_cidr must be a valid IPv4 CIDR."
  }
}

variable "tenancy_2_subnet_cidr" {
  description = "IPv4 CIDR for the acceptor private subnet."
  type        = string
  default     = "10.1.0.0/24"

  validation {
    condition     = can(cidrhost(var.tenancy_2_subnet_cidr, 0))
    error_message = "tenancy_2_subnet_cidr must be a valid IPv4 CIDR."
  }
}

variable "node_defaults" {
  description = "Shape and boot-volume defaults applied to any cluster node that does not override them."
  type = object({
    shape                   = optional(string, "VM.Standard.A1.Flex")
    ocpus                   = optional(number, 2)
    memory_in_gbs           = optional(number, 12)
    boot_volume_size_in_gbs = optional(number, 100)
    boot_volume_vpus_per_gb = optional(number, 120)
  })
  default = {}
}

variable "control_plane_count" {
  description = "Number of Talos control-plane nodes. Nodes are spread alternately across the two tenancies, starting with tenancy 1."
  type        = number
  default     = 3

  validation {
    condition     = var.control_plane_count >= 1
    error_message = "control_plane_count must be at least 1."
  }

  validation {
    condition     = var.control_plane_count % 2 == 1
    error_message = "control_plane_count must be odd so etcd can form a quorum."
  }
}

variable "worker_count" {
  description = "Number of Talos worker nodes. Workers continue the same alternating tenancy placement after the control-plane nodes."
  type        = number
  default     = 1

  validation {
    condition     = var.worker_count >= 0
    error_message = "worker_count cannot be negative."
  }
}

variable "node_host_index_base" {
  description = "First host bit assigned within each tenancy's subnet. Each additional node in that tenancy takes the next index."
  type        = number
  default     = 10

  validation {
    condition     = var.node_host_index_base >= 2 && var.node_host_index_base <= 254
    error_message = "node_host_index_base must be between 2 and 254."
  }
}
