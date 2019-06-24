output "rancher_instance_id" {
  value = "${aws_instance.rancher.id}"
}

output "ec2_security_group_id" {
  value = "${aws_security_group.rancher_ec2.id}"
}

output "elb_security_group_id" {
  value = "${aws_security_group.rancher_elb.id}"
}