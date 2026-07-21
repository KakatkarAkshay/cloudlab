output "tenancy_1_subnet_id" {
  value = oci_core_subnet.tenancy_1.id
}

output "tenancy_2_subnet_id" {
  value = oci_core_subnet.tenancy_2.id
}

output "peering_status" {
  value = oci_core_local_peering_gateway.requestor.peering_status
}

output "tenancy_1_internet_gateway_id" {
  value = oci_core_internet_gateway.tenancy_1.id
}
