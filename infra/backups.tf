resource "oci_core_volume_backup_policy" "control_plane" {
  provider = oci.tenancy_1

  compartment_id = var.tenancy_1_compartment_ocid
  display_name   = "cloudlab-control-plane-daily"

  schedules {
    backup_type       = "INCREMENTAL"
    period            = "ONE_DAY"
    retention_seconds = 172800
    offset_type       = "STRUCTURED"
    hour_of_day       = 2
    time_zone         = "UTC"
  }
}

resource "oci_core_volume_backup_policy" "worker" {
  provider = oci.tenancy_2

  compartment_id = var.tenancy_2_compartment_ocid
  display_name   = "cloudlab-worker-daily"

  schedules {
    backup_type       = "INCREMENTAL"
    period            = "ONE_DAY"
    retention_seconds = 172800
    offset_type       = "STRUCTURED"
    hour_of_day       = 2
    time_zone         = "UTC"
  }
}

resource "oci_core_volume_backup_policy_assignment" "control_plane" {
  provider = oci.tenancy_1

  asset_id  = oci_core_instance.control_plane.boot_volume_id
  policy_id = oci_core_volume_backup_policy.control_plane.id
}

resource "oci_core_volume_backup_policy_assignment" "worker" {
  provider = oci.tenancy_2

  asset_id  = oci_core_instance.worker.boot_volume_id
  policy_id = oci_core_volume_backup_policy.worker.id
}
