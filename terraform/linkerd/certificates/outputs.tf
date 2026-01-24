# ============================================================
# Certificate Outputs
# ============================================================

output "trust_anchor_cert_pem" {
  description = "Trust anchor certificate PEM"
  value       = tls_self_signed_cert.trust_anchor.cert_pem
  sensitive   = true
}

output "issuer_cert_pem" {
  description = "Issuer certificate PEM"
  value       = tls_locally_signed_cert.issuer.cert_pem
  sensitive   = true
}

output "issuer_private_key_pem" {
  description = "Issuer private key PEM"
  value       = tls_private_key.issuer.private_key_pem
  sensitive   = true
}
