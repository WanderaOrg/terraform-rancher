resource "tls_private_key" "private_key" {
  count     = var.rancher_create_cert ? 1 : 0
  algorithm = "RSA"
}

resource "acme_registration" "reg" {
  count           = var.rancher_create_cert ? 1 : 0
  account_key_pem = tls_private_key.private_key[count.index].private_key_pem
  email_address   = var.acme_registration_email
}

resource "acme_certificate" "certificate" {
  count           = var.rancher_create_cert ? 1 : 0
  account_key_pem = acme_registration.reg[count.index].account_key_pem
  common_name     = var.domain_name

  dns_challenge {
    provider = "route53"
  }
}

resource "aws_iam_server_certificate" "rancher_elb_cert" {
  count             = var.rancher_create_cert ? 1 : 0
  name_prefix       = "rancher-cert-"
  certificate_body  = acme_certificate.certificate[count.index].certificate_pem
  certificate_chain = acme_certificate.certificate[count.index].issuer_pem
  private_key       = acme_certificate.certificate[count.index].private_key_pem

  lifecycle {
    create_before_destroy = true
  }
}
