terraform {
  required_version = "~> 1.15.0"

  backend "oci" {
    bucket    = "cloudlab-terraform-state"
    namespace = "bms1yohq0tse"
    key       = "cloudlab/terraform.tfstate"
    region    = "ap-mumbai-1"
  }

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 8.23"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~> 0.11.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.9"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.3"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.5"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.22"
    }
    infisical = {
      source  = "infisical/infisical"
      version = "~> 0.19"
    }
  }
}
