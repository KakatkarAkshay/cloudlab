data "terraform_remote_state" "infra" {
  backend = "oci"

  config = {
    bucket       = "cloudlab-terraform-state"
    namespace    = "bms1yohq0tse"
    key          = "cloudlab/terraform.tfstate"
    region       = var.oci_region
    tenancy_ocid = var.tenancy_1_ocid
    user_ocid    = var.tenancy_1_user_ocid
    fingerprint  = var.oci_fingerprint
    private_key  = var.oci_private_key
  }
}

locals {
  infra = data.terraform_remote_state.infra.outputs
}
