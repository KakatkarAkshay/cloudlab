output "drg_id" {
  description = "OCID of the VPN DRG."
  value       = oci_core_drg.this.id
}

output "ipsec_id" {
  description = "OCID of the IPSec connection."
  value       = oci_core_ipsec.openwrt.id
}

output "tunnels" {
  description = "OCI tunnel endpoints and generated pre-shared keys for OpenWrt."
  value = [
    {
      display_name  = oci_core_ipsec_connection_tunnel_management.tunnel_1.display_name
      vpn_ip        = oci_core_ipsec_connection_tunnel_management.tunnel_1.vpn_ip
      shared_secret = oci_core_ipsec_connection_tunnel_management.tunnel_1.shared_secret
      ike_version   = oci_core_ipsec_connection_tunnel_management.tunnel_1.ike_version
      routing       = oci_core_ipsec_connection_tunnel_management.tunnel_1.routing
      bgp_session = {
        bgp_ipv6_state          = oci_core_ipsec_connection_tunnel_management.tunnel_1.bgp_session_info[0].bgp_ipv6_state
        bgp_state               = oci_core_ipsec_connection_tunnel_management.tunnel_1.bgp_session_info[0].bgp_state
        customer_bgp_asn        = oci_core_ipsec_connection_tunnel_management.tunnel_1.bgp_session_info[0].customer_bgp_asn
        customer_interface_ip   = oci_core_ipsec_connection_tunnel_management.tunnel_1.bgp_session_info[0].customer_interface_ip
        customer_interface_ipv6 = oci_core_ipsec_connection_tunnel_management.tunnel_1.bgp_session_info[0].customer_interface_ipv6
        oracle_bgp_asn          = oci_core_ipsec_connection_tunnel_management.tunnel_1.bgp_session_info[0].oracle_bgp_asn
        oracle_interface_ip     = oci_core_ipsec_connection_tunnel_management.tunnel_1.bgp_session_info[0].oracle_interface_ip
        oracle_interface_ipv6   = oci_core_ipsec_connection_tunnel_management.tunnel_1.bgp_session_info[0].oracle_interface_ipv6
      }
    },
    {
      display_name  = oci_core_ipsec_connection_tunnel_management.tunnel_2.display_name
      vpn_ip        = oci_core_ipsec_connection_tunnel_management.tunnel_2.vpn_ip
      shared_secret = oci_core_ipsec_connection_tunnel_management.tunnel_2.shared_secret
      ike_version   = oci_core_ipsec_connection_tunnel_management.tunnel_2.ike_version
      routing       = oci_core_ipsec_connection_tunnel_management.tunnel_2.routing
      bgp_session = {
        bgp_ipv6_state          = oci_core_ipsec_connection_tunnel_management.tunnel_2.bgp_session_info[0].bgp_ipv6_state
        bgp_state               = oci_core_ipsec_connection_tunnel_management.tunnel_2.bgp_session_info[0].bgp_state
        customer_bgp_asn        = oci_core_ipsec_connection_tunnel_management.tunnel_2.bgp_session_info[0].customer_bgp_asn
        customer_interface_ip   = oci_core_ipsec_connection_tunnel_management.tunnel_2.bgp_session_info[0].customer_interface_ip
        customer_interface_ipv6 = oci_core_ipsec_connection_tunnel_management.tunnel_2.bgp_session_info[0].customer_interface_ipv6
        oracle_bgp_asn          = oci_core_ipsec_connection_tunnel_management.tunnel_2.bgp_session_info[0].oracle_bgp_asn
        oracle_interface_ip     = oci_core_ipsec_connection_tunnel_management.tunnel_2.bgp_session_info[0].oracle_interface_ip
        oracle_interface_ipv6   = oci_core_ipsec_connection_tunnel_management.tunnel_2.bgp_session_info[0].oracle_interface_ipv6
      }
    },
  ]
  sensitive = true
}
