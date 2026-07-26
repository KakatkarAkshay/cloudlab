terraform {
  required_version = "~> 1.15.0"

  backend "oci" {
    bucket    = "cloudlab-terraform-state"
    namespace = "bms1yohq0tse"
    key       = "cloudlab/cluster.tfstate"
    region    = "ap-mumbai-1"
  }

  required_providers {
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.11.0"
    }
    flux = {
      source  = "fluxcd/flux"
      version = "~> 1.9"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.13"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.3"
    }
    infisical = {
      source  = "infisical/infisical"
      version = "~> 0.19"
    }
  }
}
