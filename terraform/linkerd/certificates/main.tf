# ============================================================
# Root CA (Trust Anchor) for Linkerd
# ============================================================

resource "tls_private_key" "trust_anchor" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_self_signed_cert" "trust_anchor" {
  private_key_pem       = tls_private_key.trust_anchor.private_key_pem
  is_ca_certificate     = true
  validity_period_hours = var.trust_anchor_validity_hours

  subject {
    common_name  = "identity.linkerd.cluster.local"
    organization = "linkerd"
  }

  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "digital_signature",
  ]
}

# ============================================================
# Issuer Certificate for Linkerd
# ============================================================

resource "tls_private_key" "issuer" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "tls_cert_request" "issuer" {
  private_key_pem = tls_private_key.issuer.private_key_pem

  subject {
    common_name  = "identity.linkerd.cluster.local"
    organization = "linkerd"
  }

  dns_names = ["identity.linkerd.cluster.local"]
}

resource "tls_locally_signed_cert" "issuer" {
  cert_request_pem      = tls_cert_request.issuer.cert_request_pem
  ca_private_key_pem    = tls_private_key.trust_anchor.private_key_pem
  ca_cert_pem           = tls_self_signed_cert.trust_anchor.cert_pem
  is_ca_certificate     = true
  validity_period_hours = var.issuer_validity_hours

  allowed_uses = [
    "cert_signing",
    "crl_signing",
    "digital_signature",
  ]
}
