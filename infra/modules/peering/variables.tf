variable "tenancy_1_ocid" {
  type = string
}

variable "tenancy_1_compartment_ocid" {
  type = string
}

variable "tenancy_1_vcn_id" {
  type = string
}

variable "tenancy_1_vcn_cidr" {
  type = string
}

variable "tenancy_1_vcn_ipv6_cidr" {
  type = string
}

variable "tenancy_1_subnet_cidr" {
  type = string
}

variable "tenancy_1_drg_id" {
  type = string
}

variable "tenancy_2_ocid" {
  type = string
}

variable "tenancy_2_compartment_ocid" {
  type = string
}

variable "tenancy_2_vcn_id" {
  type = string
}

variable "tenancy_2_vcn_cidr" {
  type = string
}

variable "tenancy_2_vcn_ipv6_cidr" {
  type = string
}

variable "tenancy_2_subnet_cidr" {
  type = string
}

variable "tenancy_2_drg_id" {
  type = string
}

variable "local_network_cidrs" {
  type = list(string)
}

variable "local_ipv6_cidrs" {
  type = list(string)
}

variable "requestor_group_name" {
  type = string
}

variable "requestor_group_ocid" {
  type = string
}
