terraform {
  required_version = "~> 1.15.0"

  backend "oci" {
    bucket    = "cloudlab-terraform-state"
    namespace = "bms1yohq0tse"
    key       = "cloudlab/proxmox.tfstate"
    region    = "ap-mumbai-1"
  }

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.111"
    }
  }
}
