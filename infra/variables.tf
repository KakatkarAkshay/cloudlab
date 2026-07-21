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

variable "requestor_group_ocid" {
  description = "OCID of the same tenancy 1 IAM group, used by the tenancy 2 admission policy."
  type        = string
}

variable "tailscale_oauth_client_id" {
  description = "OAuth client ID used to manage the dedicated Tailscale tailnet."
  type        = string
}

variable "tailscale_oauth_client_secret" {
  description = "OAuth client secret used to manage the dedicated Tailscale tailnet."
  type        = string
  sensitive   = true
}

variable "tailscale_tailnet" {
  description = "ID of the dedicated Tailscale tailnet."
  type        = string
}

variable "tenancy_1_object_storage_namespace" {
  description = "Object Storage namespace for tenancy 1."
  type        = string
  default     = "bms1yohq0tse"
}

variable "tenancy_2_object_storage_namespace" {
  description = "Object Storage namespace for tenancy 2."
  type        = string
  default     = "bmj3ksc63hbp"
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
