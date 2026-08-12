resource "oci_identity_dynamic_group" "ccm_tenancy_1" {
  provider = oci.tenancy_1

  compartment_id = var.tenancy_1_ocid
  name           = "CloudLabCCM"
  description    = "Allow the CloudLab tenancy 1 instances to run OCI CCM."
  matching_rule  = "ANY {${join(", ", [for instance in oci_core_instance.tenancy_1 : "instance.id = '${instance.id}'"])}}"
}

resource "oci_identity_policy" "ccm_tenancy_1" {
  provider = oci.tenancy_1

  compartment_id = var.tenancy_1_ocid
  name           = "CloudLabCCM"
  description    = "Allow OCI CCM to inspect cluster instances and manage network load balancers."
  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.ccm_tenancy_1.name} to read instance-family in compartment id ${var.tenancy_1_compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.ccm_tenancy_1.name} to use virtual-network-family in compartment id ${var.tenancy_1_compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.ccm_tenancy_1.name} to manage load-balancers in compartment id ${var.tenancy_1_compartment_ocid}",
  ]
}

resource "oci_identity_policy" "ccm_cross_tenancy_requestor" {
  provider = oci.tenancy_1

  compartment_id = var.tenancy_1_ocid
  name           = "CloudLabCCMCrossTenancy"
  description    = "Endorse tenancy 1's OCI CCM principals to manage load balancers and inspect resources in the peer tenancy."
  statements = [
    "Define tenancy Acceptor as ${var.tenancy_2_ocid}",
    "Endorse dynamic-group ${oci_identity_dynamic_group.ccm_tenancy_1.name} to read instance-family in tenancy Acceptor",
    "Endorse dynamic-group ${oci_identity_dynamic_group.ccm_tenancy_1.name} to use virtual-network-family in tenancy Acceptor",
    "Endorse dynamic-group ${oci_identity_dynamic_group.ccm_tenancy_1.name} to manage load-balancers in tenancy Acceptor",
  ]
}

resource "oci_identity_policy" "ccm_cross_tenancy_acceptor" {
  provider = oci.tenancy_2

  compartment_id = var.tenancy_2_ocid
  name           = "CloudLabCCMCrossTenancy"
  description    = "Admit tenancy 1's OCI CCM principals to manage load balancers and inspect resources in this tenancy."
  statements = [
    "Define tenancy Requestor as ${var.tenancy_1_ocid}",
    "Define dynamic-group RequestorCCM as ${oci_identity_dynamic_group.ccm_tenancy_1.id}",
    "Admit dynamic-group RequestorCCM of tenancy Requestor to read instance-family in compartment id ${var.tenancy_2_compartment_ocid}",
    "Admit dynamic-group RequestorCCM of tenancy Requestor to use virtual-network-family in compartment id ${var.tenancy_2_compartment_ocid}",
    "Admit dynamic-group RequestorCCM of tenancy Requestor to manage load-balancers in compartment id ${var.tenancy_2_compartment_ocid}",
  ]
}

resource "oci_identity_dynamic_group" "ccm_tenancy_2" {
  provider = oci.tenancy_2

  compartment_id = var.tenancy_2_ocid
  name           = "CloudLabCCM"
  description    = "Allow the CloudLab tenancy 2 instances to run OCI CCM."
  matching_rule  = "ANY {${join(", ", [for instance in oci_core_instance.tenancy_2 : "instance.id = '${instance.id}'"])}}"
}

resource "oci_identity_policy" "ccm_tenancy_2" {
  provider = oci.tenancy_2

  compartment_id = var.tenancy_2_ocid
  name           = "CloudLabCCM"
  description    = "Allow OCI CCM to inspect cluster instances and manage network load balancers."
  statements = [
    "Allow dynamic-group ${oci_identity_dynamic_group.ccm_tenancy_2.name} to read instance-family in compartment id ${var.tenancy_2_compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.ccm_tenancy_2.name} to use virtual-network-family in compartment id ${var.tenancy_2_compartment_ocid}",
    "Allow dynamic-group ${oci_identity_dynamic_group.ccm_tenancy_2.name} to manage load-balancers in compartment id ${var.tenancy_2_compartment_ocid}",
  ]
}

resource "oci_identity_policy" "ccm_cross_tenancy_acceptor_endorsement" {
  provider = oci.tenancy_2

  compartment_id = var.tenancy_2_ocid
  name           = "CloudLabCCMCrossTenancyEndorsement"
  description    = "Endorse tenancy 2's OCI CCM principals to manage load balancers and inspect resources in the peer tenancy."
  statements = [
    "Define tenancy Requestor as ${var.tenancy_1_ocid}",
    "Endorse dynamic-group ${oci_identity_dynamic_group.ccm_tenancy_2.name} to read instance-family in tenancy Requestor",
    "Endorse dynamic-group ${oci_identity_dynamic_group.ccm_tenancy_2.name} to use virtual-network-family in tenancy Requestor",
    "Endorse dynamic-group ${oci_identity_dynamic_group.ccm_tenancy_2.name} to manage load-balancers in tenancy Requestor",
  ]
}

resource "oci_identity_policy" "ccm_cross_tenancy_requestor_admission" {
  provider = oci.tenancy_1

  compartment_id = var.tenancy_1_ocid
  name           = "CloudLabCCMCrossTenancyAdmission"
  description    = "Admit tenancy 2's OCI CCM principals to manage load balancers and inspect resources in this tenancy."
  statements = [
    "Define tenancy Acceptor as ${var.tenancy_2_ocid}",
    "Define dynamic-group AcceptorCCM as ${oci_identity_dynamic_group.ccm_tenancy_2.id}",
    "Admit dynamic-group AcceptorCCM of tenancy Acceptor to read instance-family in compartment id ${var.tenancy_1_compartment_ocid}",
    "Admit dynamic-group AcceptorCCM of tenancy Acceptor to use virtual-network-family in compartment id ${var.tenancy_1_compartment_ocid}",
    "Admit dynamic-group AcceptorCCM of tenancy Acceptor to manage load-balancers in compartment id ${var.tenancy_1_compartment_ocid}",
  ]
}
