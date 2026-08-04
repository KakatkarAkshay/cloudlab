data "oci_objectstorage_namespace" "tenancy_1" {
  provider = oci.tenancy_1

  compartment_id = var.tenancy_1_compartment_ocid
}

data "oci_objectstorage_namespace" "tenancy_2" {
  provider = oci.tenancy_2

  compartment_id = var.tenancy_2_compartment_ocid
}

data "oci_identity_groups" "requestor" {
  provider = oci.tenancy_1

  compartment_id = var.tenancy_1_ocid

  filter {
    name   = "name"
    values = [var.requestor_group_name]
  }
}

module "tenancy_1_vcn" {
  source = "./modules/vcn"

  compartment_id = var.tenancy_1_compartment_ocid
  cidr_block     = var.tenancy_1_vcn_cidr
  display_name   = "cloudlab-tenancy-1"
  dns_label      = "cloudlab1"

  providers = {
    oci = oci.tenancy_1
  }
}

module "tenancy_2_vcn" {
  source = "./modules/vcn"

  compartment_id = var.tenancy_2_compartment_ocid
  cidr_block     = var.tenancy_2_vcn_cidr
  display_name   = "cloudlab-tenancy-2"
  dns_label      = "cloudlab2"

  providers = {
    oci = oci.tenancy_2
  }
}

module "tenancy_1_site_to_site_vpn" {
  source = "./modules/site-to-site-vpn"

  compartment_id      = var.tenancy_1_compartment_ocid
  vcn_id              = module.tenancy_1_vcn.id
  cpe_public_ip       = var.openwrt_public_ip
  local_network_cidrs = var.local_network_cidrs
  customer_bgp_asn    = var.openwrt_bgp_asn
  tunnel_bgp_sessions = var.tenancy_1_vpn_tunnel_bgp_sessions
  display_name        = "cloudlab-tenancy-1-vpn"

  providers = {
    oci = oci.tenancy_1
  }
}

module "tenancy_2_site_to_site_vpn" {
  source = "./modules/site-to-site-vpn"

  compartment_id      = var.tenancy_2_compartment_ocid
  vcn_id              = module.tenancy_2_vcn.id
  cpe_public_ip       = var.openwrt_public_ip
  local_network_cidrs = var.local_network_cidrs
  customer_bgp_asn    = var.openwrt_bgp_asn
  tunnel_bgp_sessions = var.tenancy_2_vpn_tunnel_bgp_sessions
  display_name        = "cloudlab-tenancy-2-vpn"

  providers = {
    oci = oci.tenancy_2
  }
}

module "cross_tenancy_peering" {
  source = "./modules/peering"

  tenancy_1_ocid             = var.tenancy_1_ocid
  tenancy_1_compartment_ocid = var.tenancy_1_compartment_ocid
  tenancy_1_vcn_id           = module.tenancy_1_vcn.id
  tenancy_1_vcn_cidr         = module.tenancy_1_vcn.cidr_block
  tenancy_1_vcn_ipv6_cidr    = module.tenancy_1_vcn.ipv6_cidr_block
  tenancy_1_subnet_cidr      = var.tenancy_1_subnet_cidr
  tenancy_1_drg_id           = module.tenancy_1_site_to_site_vpn.drg_id

  tenancy_2_ocid             = var.tenancy_2_ocid
  tenancy_2_compartment_ocid = var.tenancy_2_compartment_ocid
  tenancy_2_vcn_id           = module.tenancy_2_vcn.id
  tenancy_2_vcn_cidr         = module.tenancy_2_vcn.cidr_block
  tenancy_2_vcn_ipv6_cidr    = module.tenancy_2_vcn.ipv6_cidr_block
  tenancy_2_subnet_cidr      = var.tenancy_2_subnet_cidr
  tenancy_2_drg_id           = module.tenancy_2_site_to_site_vpn.drg_id

  local_network_cidrs = var.local_network_cidrs
  local_ipv6_cidrs    = var.local_ipv6_cidrs

  requestor_group_name = var.requestor_group_name
  requestor_group_ocid = data.oci_identity_groups.requestor.groups[0].id

  providers = {
    oci.tenancy_1 = oci.tenancy_1
    oci.tenancy_2 = oci.tenancy_2
  }
}
