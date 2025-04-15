resource "flux_bootstrap_git" "main" {
  path = "clusters/main"

  depends_on = [github_repository.flux_repo, helm_release.flannel]
}
