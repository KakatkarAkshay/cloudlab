variable "github_owner" {
  description = "GitHub account that owns the CloudLab repository."
  type        = string
}

variable "github_repository" {
  description = "Name of the CloudLab GitHub repository."
  type        = string
}

variable "oci_region" {
  description = "OCI region hosting the Terraform state bucket."
  type        = string
}

variable "oci_fingerprint" {
  description = "Fingerprint of the OCI API signing key."
  type        = string
}

variable "oci_private_key" {
  description = "PEM-encoded OCI API private key."
  type        = string
  sensitive   = true
}

variable "tenancy_1_ocid" {
  description = "OCID of the requestor tenancy that owns the state bucket."
  type        = string
}

variable "tenancy_1_user_ocid" {
  description = "OCID of the OCI user in the requestor tenancy."
  type        = string
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
  description = "Google OAuth client ID for oauth2-proxy."
  type        = string
  sensitive   = true
}

variable "oauth2_client_secret" {
  description = "Google OAuth client secret for oauth2-proxy."
  type        = string
  sensitive   = true
}

variable "oauth2_authorized_emails" {
  description = "Newline/comma-separated emails allowed through oauth2-proxy."
  type        = string
  sensitive   = true
}
