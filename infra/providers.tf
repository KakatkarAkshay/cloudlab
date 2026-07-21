provider "oci" {
  alias = "tenancy_1"

  tenancy_ocid = var.tenancy_1_ocid
  user_ocid    = var.tenancy_1_user_ocid
  fingerprint  = var.oci_fingerprint
  private_key  = var.oci_private_key
  region       = var.oci_region
}

provider "oci" {
  alias = "tenancy_2"

  tenancy_ocid = var.tenancy_2_ocid
  user_ocid    = var.tenancy_2_user_ocid
  fingerprint  = var.oci_fingerprint
  private_key  = var.oci_private_key
  region       = var.oci_region
}

provider "netbird" {
  token          = var.netbird_token
  management_url = var.netbird_management_url
}

provider "flux" {
  kubernetes = {
    host                   = talos_cluster_kubeconfig.cluster.kubernetes_client_configuration.host
    cluster_ca_certificate = base64decode(talos_cluster_kubeconfig.cluster.kubernetes_client_configuration.ca_certificate)
    client_certificate     = base64decode(talos_cluster_kubeconfig.cluster.kubernetes_client_configuration.client_certificate)
    client_key             = base64decode(talos_cluster_kubeconfig.cluster.kubernetes_client_configuration.client_key)
  }

  git = {
    url    = "ssh://git@github.com/abyssal-labs/cloudlab.git"
    branch = "main"
    ssh = {
      username    = "git"
      private_key = var.flux_git_ssh_private_key
    }
  }
}

provider "kubernetes" {
  host                   = talos_cluster_kubeconfig.cluster.kubernetes_client_configuration.host
  cluster_ca_certificate = base64decode(talos_cluster_kubeconfig.cluster.kubernetes_client_configuration.ca_certificate)
  client_certificate     = base64decode(talos_cluster_kubeconfig.cluster.kubernetes_client_configuration.client_certificate)
  client_key             = base64decode(talos_cluster_kubeconfig.cluster.kubernetes_client_configuration.client_key)
}
