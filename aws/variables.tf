variable "aws_region" {
  default = "eu-west-1"
}

variable "vpc_id" {}

variable "vpc_alb_subnet_ids" {
  type = "list"
}

# the subnet id should belond to the availability zone specified bellow
variable "vpc_rancher_subnet_id" {}

variable "rancher_private_ip" {
  default = ""
}

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

variable "alb_idle_timeout" {
  default = 60
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

variable "rancher_image" {
  default = "rancher/rancher"
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

variable "rancher_create_cert" {
  description = "set to false if rancher elb cert is created outside the module"
  default = true
}

variable "rancher_elb_cert_arn" {
 description = "rancher elb cert to be passed in from outside the module"
 default = ""
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

variable "s3_backup_key" {
  default = ""
}

variable "s3_backup_secret" {
  default = ""
}

variable "s3_backup_region" {
  default = ""
}

variable "s3_backup_bucket" {
  default = ""
}

variable "s3_backup_filename" {
  default = ""
}

variable "s3_backup_restore" {
  default = false
}

variable "s3_backup_schedule" {
  description = "systemd OnCalendar schedule string"
  default     = "*-*-* 4:00:00"
}

variable "fluentd_image" {
  default = "jvassev/kube-fluentd-operator:v1.8.0"
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

variable "s3cmd_version" {
  default = "2.0.2"
}
