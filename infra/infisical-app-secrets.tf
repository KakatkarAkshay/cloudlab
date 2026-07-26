resource "infisical_secret_folder" "observability" {
  project_id       = infisical_project.cloudlab.id
  environment_slug = var.infisical_environment_slug
  folder_path      = "/platform"
  name             = "observability"
}

resource "infisical_secret_folder" "github_packages" {
  project_id       = infisical_project.cloudlab.id
  environment_slug = var.infisical_environment_slug
  folder_path      = "/platform"
  name             = "github-packages"
}

resource "infisical_secret_folder" "apps" {
  project_id       = infisical_project.cloudlab.id
  environment_slug = var.infisical_environment_slug
  folder_path      = "/"
  name             = "apps"
}

resource "infisical_secret_folder" "github_actions_runner" {
  project_id       = infisical_project.cloudlab.id
  environment_slug = var.infisical_environment_slug
  folder_path      = infisical_secret_folder.apps.path
  name             = "github-actions-runner"
}

resource "infisical_secret_folder" "codex_lb" {
  project_id       = infisical_project.cloudlab.id
  environment_slug = var.infisical_environment_slug
  folder_path      = infisical_secret_folder.apps.path
  name             = "codex-lb"
}

resource "infisical_secret" "idrive_access_key_id" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.idrive_credentials.path
  name         = "ACCESS_KEY_ID"
  value        = var.idrive_access_key_id
}

resource "infisical_secret" "idrive_secret_access_key" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.idrive_credentials.path
  name         = "ACCESS_SECRET_KEY"
  value        = var.idrive_secret_access_key
}

resource "infisical_secret" "idrive_e2_endpoint" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.idrive_credentials.path
  name         = "E2_ENDPOINT"
  value        = var.idrive_e2_endpoint
}

resource "infisical_secret" "loki_bucket" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.observability.path
  name         = "LOKI_BUCKET"
  value        = var.loki_bucket
}

resource "infisical_secret" "thanos_bucket" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.observability.path
  name         = "THANOS_BUCKET"
  value        = var.thanos_bucket
}

resource "infisical_secret" "github_packages_username" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.github_packages.path
  name         = "USERNAME"
  value        = var.github_packages_username
}

resource "infisical_secret" "github_packages_token" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.github_packages.path
  name         = "TOKEN"
  value        = var.github_packages_token
}

resource "infisical_secret" "github_runner_app_id" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.github_actions_runner.path
  name         = "GITHUB_APP_ID"
  value        = var.github_runner_app_id
}

resource "infisical_secret" "github_runner_app_installation_id" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.github_actions_runner.path
  name         = "GITHUB_APP_INSTALLATION_ID"
  value        = var.github_runner_app_installation_id
}

resource "infisical_secret" "github_runner_app_private_key" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.github_actions_runner.path
  name         = "GITHUB_APP_PRIVATE_KEY"
  value        = var.github_runner_app_private_key
}

resource "infisical_secret" "codex_lb_encryption_key" {
  workspace_id = infisical_project.cloudlab.id
  env_slug     = var.infisical_environment_slug
  folder_path  = infisical_secret_folder.codex_lb.path
  name         = "ENCRYPTION_KEY"
  value        = var.codex_lb_encryption_key
}
