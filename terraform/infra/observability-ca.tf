resource "tls_private_key" "thanos_ca" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_self_signed_cert" "thanos_ca" {
  private_key_pem = tls_private_key.thanos_ca.private_key_pem

  subject {
    common_name  = "thanos-ca"
    organization = "kakatkarakshay"
  }

  validity_period_hours = 87600
  early_renewal_hours   = 8760
  is_ca_certificate     = true

  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "digital_signature",
  ]
}

resource "tls_private_key" "loki_ca" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_self_signed_cert" "loki_ca" {
  private_key_pem = tls_private_key.loki_ca.private_key_pem

  subject {
    common_name  = "loki-ca"
    organization = "kakatkarakshay"
  }

  validity_period_hours = 87600
  early_renewal_hours   = 8760
  is_ca_certificate     = true

  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "digital_signature",
  ]
}
