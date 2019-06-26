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

variable "rancher_image" {
  default = "rancher/rancher"
}

variable "rancher_ami" {
  default = "ami-08d658f84a6d84a80"
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

variable "node_exporter_version" {
  default = "0.16.0"
}

variable "node_exporter_port" {
  default = 9100
}

variable "node_exporter_path" {
  default = "/metrics"
}

variable "node_exporter_collectors" {
  default = [
    "cpu",
    "diskstats",
    "filesystem",
    "loadavg",
    "meminfo",
    "filefd",
    "netdev",
    "stat",
    "netstat",
    "systemd",
    "uname",
    "vmstat",
    "time",
    "mdadm",
    "zfs",
    "tcpstat",
    "bonding",
    "hwmon",
    "arp",
  ]
}
