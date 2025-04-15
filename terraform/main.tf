terraform {
  backend "kubernetes" {
    secret_suffix = "state"
    config_path   = "~/.kube/config"
  }
  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 6.6.0"
    }
    flux = {
      source  = "fluxcd/flux"
      version = ">= 1.5.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "3.0.0-pre2"
    }
  }
}
