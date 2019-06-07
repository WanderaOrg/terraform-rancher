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

variable "resources_additional_tags" {
  type = "map"
}

variable "rancher_image" {
  default = "rancher/rancher"
}

variable "rancher_ami" {
  default = "ami-08d658f84a6d84a80"
}

variable "rancher_instance_type" {
  default = "t3.medium"
}
