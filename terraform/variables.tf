variable "github_username" {
  type        = string
  description = "The username of the github account"
}

variable "github_repo_name" {
  type        = string
  description = "The name of the github repository"
}

variable "github_token" {
  type        = string
  description = "The token of the github account"
  sensitive   = true
}
