resource "github_repository" "flux_repo" {
  name       = var.github_repo_name
  visibility = "public"
  auto_init  = true
}
