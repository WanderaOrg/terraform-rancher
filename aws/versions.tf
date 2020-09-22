terraform {
  required_providers {
    acme = {
      source = "terraform-providers/acme"
    }
    aws = {
      source = "hashicorp/aws"
    }
    template = {
      source = "hashicorp/template"
    }
    tls = {
      source = "hashicorp/tls"
    }
  }
  required_version = ">= 0.13"
}
