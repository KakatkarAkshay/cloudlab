resource "infisical_secret_folder" "volsync" {
  project_id       = infisical_project.cloudlab.id
  environment_slug = var.infisical_environment_slug
  folder_path      = "/platform"
  name             = "volsync"
  description      = "VolSync restic repository encryption key."
}

resource "infisical_secret" "volsync_restic_password" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.volsync.path
  name         = "RESTIC_PASSWORD"
  value        = var.volsync_restic_password
}
