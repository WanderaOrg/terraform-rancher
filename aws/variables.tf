variable "aws_region" {
  default = "eu-west-1"
}

variable "vpc_id" {}

variable "vpc_alb_subnet_ids" {
  type = "list"
}

# the subnet id should belond to the availability zone specified bellow
variable "vpc_rancher_subnet_id" {}

variable "availability_zone" {}

variable "instance_public_key" {}

variable "domain_name" {}

variable "route53_zone_id" {}

variable "acme_registration_email" {
  default = "no-reply@example.com"
}

variable "alb_security_groups" {
  type = "list"
}

variable "instance_security_groups" {
  type = "list"
}

variable "cloud_tags" {
  type = "map"
}

variable "rancher_instance_hostname" {
  default = ""
}

variable "rancher_ami" {
  default = "ami-08f053fa3d25478f4"
}

variable "rancher_instance_type" {
  default = "t3.large"
}

variable "rancher_root_volume_type" {
  default = "gp2"
}

variable "rancher_root_volume_size" {
  default = 20
}

variable "rancher_storage_volume_type" {
  default = "gp2"
}

variable "rancher_storage_volume_size" {
  default = 20
}

variable "fluentd_config" {
  description = "fluentd config snippet which will be appended to syslog tail config which is present by default"
  default     = ""
}

variable "grok_pattern" {
  description = "custom grok patterns to apply to fluentd"
  default     = ""
}

variable "grok_patterns_file" {
  description = "file to load custom grok patterns"
  default     = ""
}
