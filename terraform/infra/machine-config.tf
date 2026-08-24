resource "talos_machine_secrets" "cluster" {
  talos_version = local.cluster_versions.talos
}

data "talos_machine_configuration" "control_plane" {
  cluster_name       = var.cluster_name
  machine_type       = "controlplane"
  cluster_endpoint   = "https://${local.bootstrap_ip}:6443"
  machine_secrets    = talos_machine_secrets.cluster.machine_secrets
  talos_version      = local.cluster_versions.talos
  kubernetes_version = local.cluster_versions.kubernetes

  config_patches = [
    yamlencode({
      machine = {
        nodeLabels = {
          "node.longhorn.io/create-default-disk" = "true"
          "topology.cloudlab.io/location"        = "oci"
        }
        certSANs = local.cluster_api_addresses
        kernel = {
          modules = [
            { name = "binfmt_misc" },
          ]
        }
        sysctls = {
          "net.ipv4.ip_forward"          = "1"
          "net.ipv6.conf.all.forwarding" = "1"
        }
        time = {
          servers = ["169.254.169.254"]
        }
        kubelet = {
          extraArgs = {
            rotate-server-certificates = "true"
          }
          extraConfig = {
            evictionHard = {
              "imagefs.available"  = "15%"
              "imagefs.inodesFree" = "5%"
              "memory.available"   = "1Gi"
              "nodefs.available"   = "10%"
              "nodefs.inodesFree"  = "5%"
            }
            kubeReserved = {
              memory = "512Mi"
            }
            shutdownGracePeriod             = "0s"
            shutdownGracePeriodCriticalPods = "0s"
            shutdownGracePeriodByPodPriority = [
              { priority = 0, shutdownGracePeriodSeconds = 120 },
              { priority = 1000000000, shutdownGracePeriodSeconds = 30 },
              { priority = 2000000000, shutdownGracePeriodSeconds = 20 },
              { priority = 2000001000, shutdownGracePeriodSeconds = 20 },
            ]
            systemReserved = {
              cpu                 = "50m"
              "ephemeral-storage" = "256Mi"
              memory              = "1Gi"
              pid                 = "100"
            }
          }
          extraMounts = [
            {
              destination = "/var/lib/longhorn"
              source      = "/var/mnt/longhorn"
              type        = "bind"
              options     = ["bind", "rshared", "rw"]
            },
          ]
          nodeIP = {
            validSubnets = [
              var.tenancy_1_vcn_cidr,
              module.tenancy_1_vcn.ipv6_cidr_block,
              var.tenancy_2_vcn_cidr,
              module.tenancy_2_vcn.ipv6_cidr_block,
            ]
          }
        }
      }
      cluster = {
        allowSchedulingOnControlPlanes = true
        network = {
          podSubnets     = var.kubernetes_pod_subnets
          serviceSubnets = var.kubernetes_service_subnets
        }
        apiServer = {
          certSANs = local.cluster_api_addresses
          extraArgs = {
            oidc-client-id       = "kubernetes"
            oidc-groups-claim    = "groups"
            oidc-groups-prefix   = "authentik:"
            oidc-issuer-url      = "https://auth.kakatkarakshay.dev/application/o/kubernetes/"
            oidc-username-claim  = "preferred_username"
            oidc-username-prefix = "authentik:"
          }
        }
        controllerManager = {
          extraArgs = {
            bind-address = "0.0.0.0"
          }
        }
        etcd = {
          advertisedSubnets = [
            var.tenancy_1_vcn_cidr,
            module.tenancy_1_vcn.ipv6_cidr_block,
            var.tenancy_2_vcn_cidr,
            module.tenancy_2_vcn.ipv6_cidr_block,
          ]
          extraArgs = {
            listen-metrics-urls = "http://0.0.0.0:2381"
          }
        }
        proxy = {
          extraArgs = {
            metrics-bind-address = "0.0.0.0:10249"
          }
        }
        scheduler = {
          extraArgs = {
            bind-address = "0.0.0.0"
          }
        }
      }
    }),
    yamlencode({
      machine = {
        nodeLabels = {
          "node.kubernetes.io/exclude-from-external-load-balancers" = {
            "$patch" = "delete"
          }
        }
      }
    }),
    yamlencode({
      apiVersion = "v1alpha1"
      kind       = "UserVolumeConfig"
      name       = "local-path-provisioner"
      volumeType = "directory"
    }),
    yamlencode({
      apiVersion = "v1alpha1"
      kind       = "UserVolumeConfig"
      name       = "longhorn"
      volumeType = "directory"
    }),
    yamlencode({
      apiVersion = "v1alpha1"
      kind       = "ExtensionServiceConfig"
      name       = "tailscale"
      environment = [
        "TS_AUTHKEY=${var.tailscale_client_secret}?preauthorized=true&ephemeral=false",
        "TS_EXTRA_ARGS=--advertise-tags=tag:k8s-cloudlab",
        "TS_ACCEPT_DNS=false",
      ]
    }),
  ]
}

data "talos_machine_configuration" "worker" {
  cluster_name       = var.cluster_name
  machine_type       = "worker"
  cluster_endpoint   = "https://${local.bootstrap_ip}:6443"
  machine_secrets    = talos_machine_secrets.cluster.machine_secrets
  talos_version      = local.cluster_versions.talos
  kubernetes_version = local.cluster_versions.kubernetes

  config_patches = [
    yamlencode({
      machine = {
        nodeLabels = {
          "node.longhorn.io/create-default-disk" = "true"
          "topology.cloudlab.io/location"        = "oci"
        }
        certSANs = local.cluster_api_addresses
        kernel = {
          modules = [
            { name = "binfmt_misc" },
          ]
        }
        sysctls = {
          "net.ipv4.ip_forward"          = "1"
          "net.ipv6.conf.all.forwarding" = "1"
        }
        time = {
          servers = ["169.254.169.254"]
        }
        kubelet = {
          extraArgs = {
            rotate-server-certificates = "true"
          }
          extraConfig = {
            evictionHard = {
              "imagefs.available"  = "15%"
              "imagefs.inodesFree" = "5%"
              "memory.available"   = "1Gi"
              "nodefs.available"   = "10%"
              "nodefs.inodesFree"  = "5%"
            }
            kubeReserved = {
              memory = "512Mi"
            }
            shutdownGracePeriod             = "0s"
            shutdownGracePeriodCriticalPods = "0s"
            shutdownGracePeriodByPodPriority = [
              { priority = 0, shutdownGracePeriodSeconds = 120 },
              { priority = 1000000000, shutdownGracePeriodSeconds = 30 },
              { priority = 2000000000, shutdownGracePeriodSeconds = 20 },
              { priority = 2000001000, shutdownGracePeriodSeconds = 20 },
            ]
            systemReserved = {
              cpu                 = "50m"
              "ephemeral-storage" = "256Mi"
              memory              = "1Gi"
              pid                 = "100"
            }
          }
          extraMounts = [
            {
              destination = "/var/lib/longhorn"
              source      = "/var/mnt/longhorn"
              type        = "bind"
              options     = ["bind", "rshared", "rw"]
            },
          ]
          nodeIP = {
            validSubnets = [
              var.tenancy_1_vcn_cidr,
              module.tenancy_1_vcn.ipv6_cidr_block,
              var.tenancy_2_vcn_cidr,
              module.tenancy_2_vcn.ipv6_cidr_block,
            ]
          }
        }
      }
      cluster = {
        network = {
          podSubnets     = var.kubernetes_pod_subnets
          serviceSubnets = var.kubernetes_service_subnets
        }
        proxy = {
          extraArgs = {
            metrics-bind-address = "0.0.0.0:10249"
          }
        }
      }
    }),
    yamlencode({
      apiVersion = "v1alpha1"
      kind       = "UserVolumeConfig"
      name       = "local-path-provisioner"
      volumeType = "directory"
    }),
    yamlencode({
      apiVersion = "v1alpha1"
      kind       = "UserVolumeConfig"
      name       = "longhorn"
      volumeType = "directory"
    }),
    yamlencode({
      apiVersion = "v1alpha1"
      kind       = "ExtensionServiceConfig"
      name       = "tailscale"
      environment = [
        "TS_AUTHKEY=${var.tailscale_client_secret}?preauthorized=true&ephemeral=false",
        "TS_EXTRA_ARGS=--advertise-tags=tag:k8s-cloudlab",
        "TS_ACCEPT_DNS=false",
      ]
    }),
  ]
}
