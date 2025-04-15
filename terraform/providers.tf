provider "github" {
  owner = var.github_username
  token = var.github_token
}

provider "flux" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
  git = {
    url = "https://github.com/${var.github_username}/${var.github_repo_name}.git"
    http = {
      username = var.github_username
      password = var.github_token
    }
  }
}

provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}
