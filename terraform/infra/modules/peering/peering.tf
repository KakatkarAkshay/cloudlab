resource "oci_core_local_peering_gateway" "acceptor" {
  provider = oci.tenancy_2

  compartment_id = var.tenancy_2_compartment_ocid
  vcn_id         = var.tenancy_2_vcn_id
  display_name   = "cloudlab-acceptor"

  depends_on = [oci_identity_policy.acceptor]
}

resource "oci_core_local_peering_gateway" "requestor" {
  provider = oci.tenancy_1

  compartment_id = var.tenancy_1_compartment_ocid
  vcn_id         = var.tenancy_1_vcn_id
  display_name   = "cloudlab-requestor"
  peer_id        = oci_core_local_peering_gateway.acceptor.id

  depends_on = [
    oci_identity_policy.requestor,
    oci_identity_policy.acceptor,
  ]
}
