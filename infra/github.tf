resource "tls_private_key" "flux_git" {
  algorithm = "ED25519"
}

resource "github_repository_deploy_key" "flux" {
  repository = "cloudlab"
  title      = "flux-cloudlab-terraform"
  key        = trimspace(tls_private_key.flux_git.public_key_openssh)
  read_only  = false
}

resource "github_actions_variable" "oci_region" {
  repository    = "cloudlab"
  variable_name = "OCI_REGION"
  value         = var.oci_region
}

resource "github_actions_variable" "oci_fingerprint" {
  repository    = "cloudlab"
  variable_name = "OCI_FINGERPRINT"
  value         = var.oci_fingerprint
}

resource "github_actions_variable" "oci_requestor_group_name" {
  repository    = "cloudlab"
  variable_name = "OCI_REQUESTOR_GROUP_NAME"
  value         = var.requestor_group_name
}

resource "github_actions_variable" "netbird_management_url" {
  repository    = "cloudlab"
  variable_name = "NETBIRD_MANAGEMENT_URL"
  value         = var.netbird_management_url
}

resource "github_actions_variable" "infisical_org_id" {
  repository    = "cloudlab"
  variable_name = "INFISICAL_ORG_ID"
  value         = var.infisical_org_id
}

resource "github_actions_variable" "infisical_machine_identity_id" {
  repository    = "cloudlab"
  variable_name = "INFISICAL_MACHINE_IDENTITY_ID"
  value         = infisical_identity.terraform.id
}
