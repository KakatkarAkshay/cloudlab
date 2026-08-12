resource "infisical_project" "cloudlab" {
  name = "CloudLab"
  slug = "cloudlab"
}

resource "infisical_identity" "terraform" {
  name   = "Terraform"
  org_id = var.infisical_org_id
  role   = "admin"
}

resource "infisical_project_identity" "terraform" {
  project_id     = infisical_project.cloudlab.id
  identity_id    = infisical_identity.terraform.id
  adopt_existing = true

  roles = [
    { role_slug = "admin" },
  ]
}

resource "infisical_identity" "external_secrets" {
  name                  = "cloudlab-eso"
  org_id                = var.infisical_org_id
  role                  = "no-access"
  has_delete_protection = false
}

resource "infisical_project_identity" "external_secrets" {
  project_id     = infisical_project.cloudlab.id
  identity_id    = infisical_identity.external_secrets.id
  adopt_existing = true

  roles = [
    { role_slug = "viewer" },
  ]
}

resource "infisical_secret_folder" "cloudflare" {
  project_id       = infisical_project.cloudlab.id
  environment_slug = var.infisical_environment_slug
  folder_path      = "/platform"
  name             = "cloudflare"
  description      = "Cloudflare credentials for external-dns."
}

resource "infisical_secret_folder" "idrive_credentials" {
  project_id       = infisical_project.cloudlab.id
  environment_slug = var.infisical_environment_slug
  folder_path      = "/platform"
  name             = "idrive-credentials"
  description      = "iDrive E2 S3-compatible credentials."
}

resource "infisical_secret" "cloudflare_api_token" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.cloudflare.path
  name         = "API_TOKEN"
  value        = cloudflare_account_token.external_dns.value
}

resource "infisical_secret_folder" "oci_cloud_controller_manager" {
  project_id       = infisical_project.cloudlab.id
  environment_slug = var.infisical_environment_slug
  folder_path      = "/platform"
  name             = "oci-cloud-controller-manager"
  description      = "OCI Cloud Controller Manager configuration."
}

resource "infisical_secret_folder" "oci_tenancy_1" {
  project_id       = infisical_project.cloudlab.id
  environment_slug = var.infisical_environment_slug
  folder_path      = infisical_secret_folder.oci_cloud_controller_manager.path
  name             = "tenancy-1"
  description      = "OCI tenancy 1 placement."
}

resource "infisical_secret_folder" "oci_tenancy_2" {
  project_id       = infisical_project.cloudlab.id
  environment_slug = var.infisical_environment_slug
  folder_path      = infisical_secret_folder.oci_cloud_controller_manager.path
  name             = "tenancy-2"
  description      = "OCI tenancy 2 placement."
}

resource "infisical_secret" "oci_tenancy_1_compartment_id" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.oci_tenancy_1.path
  name         = "COMPARTMENT_ID"
  value        = var.tenancy_1_compartment_ocid
}

resource "infisical_secret" "oci_tenancy_1_vcn_id" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.oci_tenancy_1.path
  name         = "VCN_ID"
  value        = module.tenancy_1_vcn.id
}

resource "infisical_secret" "oci_tenancy_1_nlb_subnet_id" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.oci_tenancy_1.path
  name         = "NLB_SUBNET_ID"
  value        = oci_core_subnet.nlb.id
}

resource "infisical_secret" "oci_tenancy_2_compartment_id" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.oci_tenancy_2.path
  name         = "COMPARTMENT_ID"
  value        = var.tenancy_2_compartment_ocid
}

resource "infisical_secret" "oci_tenancy_2_vcn_id" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.oci_tenancy_2.path
  name         = "VCN_ID"
  value        = module.tenancy_2_vcn.id
}

resource "infisical_secret" "oci_tenancy_2_nlb_subnet_id" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.oci_tenancy_2.path
  name         = "NLB_SUBNET_ID"
  value        = oci_core_subnet.nlb_tenancy_2.id
}


resource "infisical_secret" "idrive_aws_region" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.idrive_credentials.path
  name         = "AWS_REGION"
  value        = var.idrive_aws_region
}
