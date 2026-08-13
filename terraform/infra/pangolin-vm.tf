resource "tls_private_key" "pangolin_vm" {
  algorithm = "ED25519"
}

data "http" "pangolin_vm_github_keys" {
  url = "https://github.com/${var.github_owner}.keys"
}

locals {
  pangolin_vm_authorized_keys = join("\n", compact(concat(
    [trimspace(tls_private_key.pangolin_vm.public_key_openssh)],
    [trimspace(data.http.pangolin_vm_github_keys.response_body)],
  )))

  pangolin_node_hostname = "node.${var.cloudflare_zone}"

  pangolin_node_config = templatefile("${path.module}/files/config.yml.tftpl", {
    node_endpoint = local.pangolin_node_hostname
    hybrid_id     = var.pangolin_node_hybrid_id
    hybrid_secret = var.pangolin_node_hybrid_secret
  })

  pangolin_node_compose = templatefile("${path.module}/files/docker-compose.yml.tftpl", {
    pangolin_node_version = var.pangolin_node_version
    gerbil_version        = var.gerbil_version
    traefik_version       = var.pangolin_node_traefik_version
  })

  pangolin_node_traefik_config = templatefile("${path.module}/files/traefik_config.yml.tftpl", {
    badger_version = var.pangolin_node_badger_version
  })

  pangolin_vm_cloud_init = <<-CLOUDINIT
    #cloud-config
    package_update: true
    packages:
      - docker.io
      - docker-compose-v2
    swap:
      filename: /swapfile
      size: 2147483648
    write_files:
      - path: /etc/sysctl.d/99-pangolin.conf
        content: |
          net.ipv4.ip_forward = 1
          net.ipv6.conf.all.forwarding = 1
      - path: /opt/pangolin/config/config.yml
        permissions: "0600"
        content: |
          ${indent(6, local.pangolin_node_config)}
      - path: /opt/pangolin/config/traefik/traefik_config.yml
        content: |
          ${indent(6, local.pangolin_node_traefik_config)}
      - path: /opt/pangolin/docker-compose.yml
        content: |
          ${indent(6, local.pangolin_node_compose)}
    runcmd:
      - sysctl --system
      - systemctl enable --now docker
      # OCI images ship an iptables policy that only admits SSH.
      - iptables -I INPUT 1 -p tcp --dport 80 -j ACCEPT
      - iptables -I INPUT 1 -p tcp --dport 443 -j ACCEPT
      - iptables -I INPUT 1 -p udp --dport 443 -j ACCEPT
      - iptables -I INPUT 1 -p udp --dport 51820 -j ACCEPT
      - iptables -I INPUT 1 -p udp --dport 21820 -j ACCEPT
      - netfilter-persistent save
      - docker compose -f /opt/pangolin/docker-compose.yml up -d
  CLOUDINIT
}

resource "oci_core_route_table" "pangolin_public" {
  provider = oci.tenancy_2

  compartment_id = var.tenancy_2_compartment_ocid
  vcn_id         = module.tenancy_2_vcn.id
  display_name   = "cloudlab-pangolin-public"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = module.cross_tenancy_peering.tenancy_2_internet_gateway_id
  }

  route_rules {
    destination       = "::/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = module.cross_tenancy_peering.tenancy_2_internet_gateway_id
  }

  route_rules {
    destination       = var.tenancy_1_vcn_cidr
    destination_type  = "CIDR_BLOCK"
    network_entity_id = module.cross_tenancy_peering.tenancy_2_local_peering_gateway_id
  }
}

resource "oci_core_security_list" "pangolin_public" {
  provider = oci.tenancy_2

  compartment_id = var.tenancy_2_compartment_ocid
  vcn_id         = module.tenancy_2_vcn.id
  display_name   = "cloudlab-pangolin-public"

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "HTTP for ACME and redirects"

    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "HTTPS"

    tcp_options {
      min = 443
      max = 443
    }
  }

  ingress_security_rules {
    protocol    = "17"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "HTTP/3 QUIC"

    udp_options {
      min = 443
      max = 443
    }
  }

  ingress_security_rules {
    protocol    = "17"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "WireGuard tunnel"

    udp_options {
      min = 51820
      max = 51820
    }
  }

  ingress_security_rules {
    protocol    = "17"
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "NAT hole punch"

    udp_options {
      min = 21820
      max = 21820
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = var.pangolin_vm_ssh_source_cidr
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "SSH administration"

    tcp_options {
      min = 22
      max = 22
    }
  }

  ingress_security_rules {
    protocol    = "all"
    source      = var.tenancy_2_vcn_cidr
    source_type = "CIDR_BLOCK"
    stateless   = false
    description = "Allow traffic within the acceptor VCN"
  }

  egress_security_rules {
    protocol         = "all"
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    stateless        = false
    description      = "Allow outbound internet access"
  }

  egress_security_rules {
    protocol         = "all"
    destination      = "::/0"
    destination_type = "CIDR_BLOCK"
    stateless        = false
    description      = "Allow outbound IPv6 access"
  }
}

resource "oci_core_subnet" "pangolin_public" {
  provider = oci.tenancy_2

  compartment_id             = var.tenancy_2_compartment_ocid
  vcn_id                     = module.tenancy_2_vcn.id
  cidr_block                 = var.pangolin_vm_subnet_cidr
  ipv6cidr_block             = cidrsubnet(module.tenancy_2_vcn.ipv6_cidr_block, 8, 2)
  display_name               = "cloudlab-pangolin-public"
  dns_label                  = "pangolin"
  prohibit_public_ip_on_vnic = false
  prohibit_internet_ingress  = false
  route_table_id             = oci_core_route_table.pangolin_public.id
  security_list_ids          = [oci_core_security_list.pangolin_public.id]
}

data "oci_core_images" "pangolin_vm" {
  provider = oci.tenancy_2

  compartment_id           = var.tenancy_2_compartment_ocid
  operating_system         = "Canonical Ubuntu"
  operating_system_version = "24.04 Minimal"
  shape                    = var.pangolin_vm_shape
  sort_by                  = "TIMECREATED"
  sort_order               = "DESC"
}

resource "oci_core_instance" "pangolin" {
  provider = oci.tenancy_2

  availability_domain = data.oci_identity_availability_domains.tenancy_2.availability_domains[0].name
  compartment_id      = var.tenancy_2_compartment_ocid
  display_name        = "cloudlab-pangolin"
  shape               = var.pangolin_vm_shape

  create_vnic_details {
    assign_ipv6ip    = true
    assign_public_ip = "true"
    hostname_label   = "pangolin"
    subnet_id        = oci_core_subnet.pangolin_public.id
  }

  metadata = {
    ssh_authorized_keys = local.pangolin_vm_authorized_keys
    user_data           = base64encode(local.pangolin_vm_cloud_init)
  }

  source_details {
    source_type                     = "image"
    source_id                       = data.oci_core_images.pangolin_vm.images[0].id
    boot_volume_size_in_gbs         = tostring(var.pangolin_vm_boot_volume_size_in_gbs)
    boot_volume_vpus_per_gb         = tostring(var.pangolin_vm_boot_volume_vpus_per_gb)
    is_preserve_boot_volume_enabled = false
  }

  lifecycle {
    ignore_changes = [source_details[0].source_id]
  }
}

resource "cloudflare_dns_record" "pangolin_node" {
  zone_id = data.cloudflare_zone.cloudlab.id
  name    = local.pangolin_node_hostname
  type    = "A"
  content = oci_core_instance.pangolin.public_ip
  ttl     = 60
  proxied = false
}

resource "cloudflare_dns_record" "homelab_gateway" {
  zone_id = data.cloudflare_zone.cloudlab.id
  name    = "homelab-gateway.${var.cloudflare_zone}"
  type    = "CNAME"
  content = local.pangolin_node_hostname
  ttl     = 60
  proxied = false
}

output "pangolin_node_hostname" {
  description = "Public name clients and sites reach the Pangolin node on."
  value       = local.pangolin_node_hostname
}

output "pangolin_vm_public_ip" {
  description = "Public IPv4 address of the Pangolin host."
  value       = oci_core_instance.pangolin.public_ip
}

output "pangolin_vm_private_ip" {
  description = "Private address the Pangolin host uses to reach the cluster."
  value       = oci_core_instance.pangolin.private_ip
}

output "pangolin_vm_ssh_private_key" {
  description = "Generated SSH private key for the Pangolin host."
  value       = tls_private_key.pangolin_vm.private_key_openssh
  sensitive   = true
}
