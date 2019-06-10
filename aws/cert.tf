provider "acme" {
  server_url = "${var.acme_server_url}"
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "reg" {
  account_key_pem = "${tls_private_key.private_key.private_key_pem}"
  email_address   = "${var.acme_registration_email}"
}

resource "acme_certificate" "certificate" {
  account_key_pem = "${acme_registration.reg.account_key_pem}"
  common_name     = "${var.domain_name}"

  dns_challenge {
    provider = "route53"
  }
}

resource "aws_iam_server_certificate" "rancher_elb_cert" {
  name_prefix       = "rancher-cert-"
  certificate_body  = "${acme_certificate.certificate.certificate_pem}"
  certificate_chain = "${acme_certificate.certificate.issuer_pem}"
  private_key       = "${acme_certificate.certificate.private_key_pem}"

  lifecycle {
    create_before_destroy = true
  }
}
