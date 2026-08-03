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
      bgp_session   = oci_core_ipsec_connection_tunnel_management.tunnel_1.bgp_session_info[0]
    },
    {
      display_name  = oci_core_ipsec_connection_tunnel_management.tunnel_2.display_name
      vpn_ip        = oci_core_ipsec_connection_tunnel_management.tunnel_2.vpn_ip
      shared_secret = oci_core_ipsec_connection_tunnel_management.tunnel_2.shared_secret
      ike_version   = oci_core_ipsec_connection_tunnel_management.tunnel_2.ike_version
      routing       = oci_core_ipsec_connection_tunnel_management.tunnel_2.routing
      bgp_session   = oci_core_ipsec_connection_tunnel_management.tunnel_2.bgp_session_info[0]
    },
  ]
  sensitive = true
}
