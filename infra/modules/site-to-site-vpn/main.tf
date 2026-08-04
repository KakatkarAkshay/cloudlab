resource "oci_core_drg" "this" {
  compartment_id = var.compartment_id
  display_name   = "${var.display_name}-drg"
}

resource "oci_core_drg_attachment" "vcn" {
  drg_id       = oci_core_drg.this.id
  display_name = "${var.display_name}-vcn"

  network_details {
    id             = var.vcn_id
    type           = "VCN"
    vcn_route_type = "VCN_CIDRS"
  }
}

resource "oci_core_cpe" "openwrt" {
  compartment_id = var.compartment_id
  ip_address     = var.cpe_public_ip
  display_name   = "${var.display_name}-openwrt"
}

resource "oci_core_ipsec" "openwrt" {
  compartment_id = var.compartment_id
  cpe_id         = oci_core_cpe.openwrt.id
  drg_id         = oci_core_drg.this.id
  static_routes  = var.local_network_cidrs
  display_name   = "${var.display_name}-openwrt"
}

data "oci_core_ipsec_connection_tunnels" "openwrt" {
  ipsec_id = oci_core_ipsec.openwrt.id
}

resource "oci_core_ipsec_connection_tunnel_management" "tunnel_1" {
  ipsec_id     = oci_core_ipsec.openwrt.id
  tunnel_id    = data.oci_core_ipsec_connection_tunnels.openwrt.ip_sec_connection_tunnels[0].id
  display_name = "${var.display_name}-tunnel-1"
  ike_version  = "V2"
  routing      = "BGP"

  bgp_session_info {
    customer_bgp_asn        = tostring(var.customer_bgp_asn)
    customer_interface_ip   = var.tunnel_bgp_sessions[0].customer_interface_ip
    oracle_interface_ip     = var.tunnel_bgp_sessions[0].oracle_interface_ip
    customer_interface_ipv6 = var.tunnel_bgp_sessions[0].customer_interface_ipv6
    oracle_interface_ipv6   = var.tunnel_bgp_sessions[0].oracle_interface_ipv6
  }
}

resource "oci_core_ipsec_connection_tunnel_management" "tunnel_2" {
  ipsec_id     = oci_core_ipsec.openwrt.id
  tunnel_id    = data.oci_core_ipsec_connection_tunnels.openwrt.ip_sec_connection_tunnels[1].id
  display_name = "${var.display_name}-tunnel-2"
  ike_version  = "V2"
  routing      = "BGP"

  bgp_session_info {
    customer_bgp_asn        = tostring(var.customer_bgp_asn)
    customer_interface_ip   = var.tunnel_bgp_sessions[1].customer_interface_ip
    oracle_interface_ip     = var.tunnel_bgp_sessions[1].oracle_interface_ip
    customer_interface_ipv6 = var.tunnel_bgp_sessions[1].customer_interface_ipv6
    oracle_interface_ipv6   = var.tunnel_bgp_sessions[1].oracle_interface_ipv6
  }
}
