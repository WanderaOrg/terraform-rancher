resource "aws_security_group" "rancher_ec2" {
  name = "rancher_ec2"
  vpc_id = "${var.vpc_id}"

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "rancher_ec2_from_elb" {
  security_group_id = "${aws_security_group.rancher_ec2.id}"
  source_security_group_id = "${aws_security_group.rancher_elb.id}"

  from_port = 8443
  to_port = 8443
  protocol = "TCP"
  type = "ingress"
}

resource "aws_security_group" "rancher_elb" {
  name = "rancher_elb"
  description = "Allow all inbound traffic"
  vpc_id = "${var.vpc_id}"
}

resource "aws_security_group_rule" "rancher_elb" {
  security_group_id = "${aws_security_group.rancher_elb.id}"
  source_security_group_id = "${aws_security_group.rancher_ec2.id}"

  from_port = 8443
  to_port = 8443
  protocol = "TCP"
  type = "egress"
}
