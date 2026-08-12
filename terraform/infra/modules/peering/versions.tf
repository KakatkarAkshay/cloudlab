terraform {
  required_providers {
    oci = {
      source                = "oracle/oci"
      configuration_aliases = [oci.tenancy_1, oci.tenancy_2]
    }
  }
}
