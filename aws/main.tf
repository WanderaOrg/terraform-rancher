resource "aws_ebs_volume" "rancher_ebs" {
  availability_zone = "${var.instance_availability_zone}"
  size              = 20
  tags {
    Name = "rancher"
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = "${aws_ebs_volume.rancher_ebs.id}"
  instance_id = "${aws_instance.rancher.id}"
}

resource "aws_instance" "rancher" {
  ami = "ami-08d658f84a6d84a80"
  instance_type = "t3.medium"
  availability_zone = "${var.instance_availability_zone}"
  subnet_id = "${var.vpc_subnet_id_instance}"
  key_name = "${aws_key_pair.rancher-key.key_name}"
  vpc_security_group_ids = [
    "${aws_security_group.rancher_ec2.id}",
  ]

  root_block_device {
    volume_size = 20
    volume_type = "gp2"
    delete_on_termination = true
  }

  user_data = "${base64encode(file("${path.module}/user-data.sh"))}"

  tags {
    Name = "rancher"
  }
}

resource "aws_key_pair" "rancher-key" {
  key_name = "rancher-key"
  public_key = "${var.instance_public_key}"
}

resource "aws_route53_record" "rancher" {
  name = "${var.domain_name}"
  type = "A"
  zone_id = "${var.domain_zone_id}"

  alias {
    name                   = "${aws_lb.rancher_lb.dns_name}"
    zone_id                = "${aws_lb.rancher_lb.zone_id}"
    evaluate_target_health = true
  }
}
