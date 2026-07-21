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
  token          = var.netbird_token
  management_url = var.netbird_management_url
}
