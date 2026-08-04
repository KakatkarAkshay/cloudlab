resource "oci_core_volume_backup_policy" "triton" {
  provider = oci.tenancy_1

  compartment_id = var.tenancy_1_compartment_ocid
  display_name   = "cloudlab-triton-daily"

  schedules {
    backup_type       = "INCREMENTAL"
    period            = "ONE_DAY"
    retention_seconds = 172800
    offset_type       = "STRUCTURED"
    hour_of_day       = 2
    time_zone         = "UTC"
  }
}

resource "oci_core_volume_backup_policy" "scorpion" {
  provider = oci.tenancy_2

  compartment_id = var.tenancy_2_compartment_ocid
  display_name   = "cloudlab-scorpion-daily"

  schedules {
    backup_type       = "INCREMENTAL"
    period            = "ONE_DAY"
    retention_seconds = 172800
    offset_type       = "STRUCTURED"
    hour_of_day       = 2
    time_zone         = "UTC"
  }
}

resource "oci_core_volume_backup_policy_assignment" "triton" {
  provider = oci.tenancy_1

  asset_id  = oci_core_instance.triton.boot_volume_id
  policy_id = oci_core_volume_backup_policy.triton.id
}

resource "oci_core_volume_backup_policy_assignment" "scorpion" {
  provider = oci.tenancy_2

  asset_id  = oci_core_instance.scorpion.boot_volume_id
  policy_id = oci_core_volume_backup_policy.scorpion.id
}
