resource "oci_identity_policy" "requestor" {
  provider = oci.tenancy_1

  compartment_id = var.tenancy_1_ocid
  name           = "CloudLabCrossTenancyPeering"
  description    = "Authorize the requestor group to establish cross-tenancy local VCN peering."
  statements = [
    "Define tenancy Acceptor as ${var.tenancy_2_ocid}",
    "Endorse group ${var.requestor_group_name} to manage local-peering-to in tenancy Acceptor",
    "Endorse group ${var.requestor_group_name} to associate local-peering-gateways in tenancy with local-peering-gateways in tenancy Acceptor",
    "Allow group ${var.requestor_group_name} to manage local-peering-from in tenancy",
  ]
}

resource "oci_identity_policy" "acceptor" {
  provider = oci.tenancy_2

  compartment_id = var.tenancy_2_ocid
  name           = "CloudLabCrossTenancyPeering"
  description    = "Admit the requestor group to establish cross-tenancy local VCN peering."
  statements = [
    "Define tenancy Requestor as ${var.tenancy_1_ocid}",
    "Define group RequestorGroup as ${var.requestor_group_ocid}",
    "Admit group RequestorGroup of tenancy Requestor to manage local-peering-to in tenancy",
    "Admit group RequestorGroup of tenancy Requestor to associate local-peering-gateways in tenancy Requestor with local-peering-gateways in tenancy",
  ]
}
