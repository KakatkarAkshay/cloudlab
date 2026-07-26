provider "oci" {
  alias = "tenancy_1"

  tenancy_ocid = var.tenancy_1_ocid
  user_ocid    = var.tenancy_1_user_ocid
  fingerprint  = var.oci_fingerprint
  private_key  = var.oci_private_key
  region       = var.oci_region
}

provider "oci" {
  alias = "tenancy_2"

  tenancy_ocid = var.tenancy_2_ocid
  user_ocid    = var.tenancy_2_user_ocid
  fingerprint  = var.oci_fingerprint
  private_key  = var.oci_private_key
  region       = var.oci_region
}

provider "netbird" {
  token = var.netbird_token
}

# Reads CLOUDFLARE_API_TOKEN from the environment.
provider "cloudflare" {}

# Uses OIDC in CI and Universal Auth for local administration.
provider "infisical" {
  host = var.infisical_host
  auth = {
    oidc      = var.infisical_auth_method == "oidc" ? {} : null
    universal = var.infisical_auth_method == "universal" ? {} : null
  }
}
