locals {
  cluster_versions   = jsondecode(file("${path.module}/../../cluster-versions.json"))
  talos_image_object = "talos-${local.cluster_versions.talos}-${talos_image_factory_schematic.cluster.id}-oracle-arm64.qcow2"
  talos_image_path   = "${path.module}/build/${local.talos_image_object}"

  talos_image_capabilities = {
    "Compute.Firmware" = jsonencode({
      descriptorType = "enumstring"
      source         = "IMAGE"
      defaultValue   = "UEFI_64"
      values         = ["UEFI_64"]
    })
    "Network.AttachmentType" = jsonencode({
      descriptorType = "enumstring"
      source         = "IMAGE"
      defaultValue   = "PARAVIRTUALIZED"
      values         = ["PARAVIRTUALIZED"]
    })
    "Storage.BootVolumeType" = jsonencode({
      descriptorType = "enumstring"
      source         = "IMAGE"
      defaultValue   = "PARAVIRTUALIZED"
      values         = ["PARAVIRTUALIZED"]
    })
    "Storage.RemoteDataVolumeType" = jsonencode({
      descriptorType = "enumstring"
      source         = "IMAGE"
      defaultValue   = "PARAVIRTUALIZED"
      values         = ["PARAVIRTUALIZED"]
    })
    "Storage.ConsistentVolumeNaming" = jsonencode({
      descriptorType = "boolean"
      source         = "IMAGE"
      defaultValue   = true
    })
    "Storage.ParaVirtualization.EncryptionInTransit" = jsonencode({
      descriptorType = "boolean"
      source         = "IMAGE"
      defaultValue   = true
    })
  }
}

resource "talos_image_factory_schematic" "cluster" {
  schematic = file("${path.module}/talos-schematic.yaml")
}

data "talos_image_factory_urls" "oracle_arm64" {
  talos_version = local.cluster_versions.talos
  schematic_id  = talos_image_factory_schematic.cluster.id
  platform      = "oracle"
  architecture  = "arm64"
}

data "local_command" "talos_image" {
  command = "curl"
  arguments = [
    "--fail",
    "--location",
    "--silent",
    "--show-error",
    "--create-dirs",
    "--output",
    local.talos_image_path,
    data.talos_image_factory_urls.oracle_arm64.urls.disk_image,
  ]
}

resource "oci_objectstorage_bucket" "talos_tenancy_1" {
  provider = oci.tenancy_1

  compartment_id = var.tenancy_1_compartment_ocid
  namespace      = data.oci_objectstorage_namespace.tenancy_1.namespace
  name           = "cloudlab-talos-images"
  access_type    = "NoPublicAccess"
}

resource "oci_objectstorage_bucket" "talos_tenancy_2" {
  provider = oci.tenancy_2

  compartment_id = var.tenancy_2_compartment_ocid
  namespace      = data.oci_objectstorage_namespace.tenancy_2.namespace
  name           = "cloudlab-talos-images"
  access_type    = "NoPublicAccess"
}

resource "oci_objectstorage_object" "talos_tenancy_1" {
  provider = oci.tenancy_1

  bucket    = oci_objectstorage_bucket.talos_tenancy_1.name
  namespace = data.oci_objectstorage_namespace.tenancy_1.namespace
  object    = local.talos_image_object
  source    = local.talos_image_path

  depends_on = [data.local_command.talos_image]

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [source]
  }
}

resource "oci_objectstorage_object" "talos_tenancy_2" {
  provider = oci.tenancy_2

  bucket    = oci_objectstorage_bucket.talos_tenancy_2.name
  namespace = data.oci_objectstorage_namespace.tenancy_2.namespace
  object    = local.talos_image_object
  source    = local.talos_image_path

  depends_on = [data.local_command.talos_image]

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [source]
  }
}

resource "oci_core_image" "talos_tenancy_1" {
  provider = oci.tenancy_1

  compartment_id = var.tenancy_1_compartment_ocid
  display_name   = "Talos ${local.cluster_versions.talos} ARM64"
  launch_mode    = "PARAVIRTUALIZED"

  image_source_details {
    source_type              = "objectStorageTuple"
    namespace_name           = data.oci_objectstorage_namespace.tenancy_1.namespace
    bucket_name              = oci_objectstorage_bucket.talos_tenancy_1.name
    object_name              = oci_objectstorage_object.talos_tenancy_1.object
    operating_system         = "Talos"
    operating_system_version = trimprefix(local.cluster_versions.talos, "v")
    source_image_type        = "QCOW2"
  }

  # Attributes are ignored because OCI normalises them; a new uploaded object
  # is what should actually roll the image.
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [display_name, image_source_details]
    replace_triggered_by  = [oci_objectstorage_object.talos_tenancy_1]
  }
}

resource "oci_core_image" "talos_tenancy_2" {
  provider = oci.tenancy_2

  compartment_id = var.tenancy_2_compartment_ocid
  display_name   = "Talos ${local.cluster_versions.talos} ARM64"
  launch_mode    = "PARAVIRTUALIZED"

  image_source_details {
    source_type              = "objectStorageTuple"
    namespace_name           = data.oci_objectstorage_namespace.tenancy_2.namespace
    bucket_name              = oci_objectstorage_bucket.talos_tenancy_2.name
    object_name              = oci_objectstorage_object.talos_tenancy_2.object
    operating_system         = "Talos"
    operating_system_version = trimprefix(local.cluster_versions.talos, "v")
    source_image_type        = "QCOW2"
  }

  # Attributes are ignored because OCI normalises them; a new uploaded object
  # is what should actually roll the image.
  lifecycle {
    create_before_destroy = true
    ignore_changes        = [display_name, image_source_details]
    replace_triggered_by  = [oci_objectstorage_object.talos_tenancy_2]
  }
}

data "oci_core_compute_global_image_capability_schemas" "tenancy_1" {
  provider = oci.tenancy_1
}

data "oci_core_compute_global_image_capability_schema" "tenancy_1" {
  provider = oci.tenancy_1

  compute_global_image_capability_schema_id = data.oci_core_compute_global_image_capability_schemas.tenancy_1.compute_global_image_capability_schemas[0].id
}

data "oci_core_compute_global_image_capability_schemas" "tenancy_2" {
  provider = oci.tenancy_2
}

data "oci_core_compute_global_image_capability_schema" "tenancy_2" {
  provider = oci.tenancy_2

  compute_global_image_capability_schema_id = data.oci_core_compute_global_image_capability_schemas.tenancy_2.compute_global_image_capability_schemas[0].id
}

resource "oci_core_compute_image_capability_schema" "talos_tenancy_1" {
  provider = oci.tenancy_1

  compartment_id                                      = var.tenancy_1_compartment_ocid
  compute_global_image_capability_schema_version_name = data.oci_core_compute_global_image_capability_schema.tenancy_1.current_version_name
  display_name                                        = "Talos ARM64 capabilities"
  image_id                                            = oci_core_image.talos_tenancy_1.id
  schema_data                                         = local.talos_image_capabilities
}

resource "oci_core_compute_image_capability_schema" "talos_tenancy_2" {
  provider = oci.tenancy_2

  compartment_id                                      = var.tenancy_2_compartment_ocid
  compute_global_image_capability_schema_version_name = data.oci_core_compute_global_image_capability_schema.tenancy_2.current_version_name
  display_name                                        = "Talos ARM64 capabilities"
  image_id                                            = oci_core_image.talos_tenancy_2.id
  schema_data                                         = local.talos_image_capabilities
}

resource "oci_core_shape_management" "talos_tenancy_1" {
  provider = oci.tenancy_1

  compartment_id = var.tenancy_1_compartment_ocid
  image_id       = oci_core_image.talos_tenancy_1.id
  shape_name     = "VM.Standard.A1.Flex"

  depends_on = [oci_core_compute_image_capability_schema.talos_tenancy_1]
}

resource "oci_core_shape_management" "talos_tenancy_2" {
  provider = oci.tenancy_2

  compartment_id = var.tenancy_2_compartment_ocid
  image_id       = oci_core_image.talos_tenancy_2.id
  shape_name     = "VM.Standard.A1.Flex"

  depends_on = [oci_core_compute_image_capability_schema.talos_tenancy_2]
}
