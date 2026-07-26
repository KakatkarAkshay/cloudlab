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
