terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "6.28.0"
    }

    http = {
      source  = "hashicorp/http"
      version = "~> 2.0"
    }
    ssh = {
      source  = "toowoxx/ssh"
      version = "1.0.1"
    }
  }
}
