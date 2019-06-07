variable "aws_region" {
  default = "eu-west-1"
}

variable "vpc_id" {}

variable "vpc_subnet_ids" {
  type = "list"
}

variable "vpc_subnet_id_instance" {}

variable "instance_availability_zone" {}

variable "instance_public_key" {}

variable "domain_name" {}

variable "domain_zone_id" {}

variable "acme_server_url" {
  default = "https://acme-staging-v02.api.letsencrypt.org/directory"
}

variable "acme_registration_email" {
  default = "no-reply@example.com"
}

variable "security_groups" {
  type = "list"
}

variable "rancher_image" {
  default = "rancher/rancher"
}

variable "resources_additional_tags" {
  type = "map"
}
