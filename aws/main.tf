resource "aws_ebs_volume" "rancher_ebs" {
  availability_zone = "${var.availability_zone}"
  size              = 20
  tags              = "${merge(map("Name", "rancher"), var.cloud_tags)}"
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = "${aws_ebs_volume.rancher_ebs.id}"
  instance_id = "${aws_instance.rancher.id}"
}

data "template_file" "user_data" {
  template = "${file("${path.module}/user-data.tpl")}"

  vars = {
    rancher_image = "${var.rancher_image}"
  }
}

resource "aws_instance" "rancher" {
  ami               = "${var.rancher_ami}"
  instance_type     = "${var.rancher_instance_type}"
  availability_zone = "${var.availability_zone}"
  subnet_id         = "${var.vpc_rancher_subnet_id}"
  key_name          = "${aws_key_pair.rancher-key.key_name}"

  vpc_security_group_ids = ["${concat(list(aws_security_group.rancher_ec2.id), var.security_groups)}"]

  root_block_device {
    volume_size           = 20
    volume_type           = "gp2"
    delete_on_termination = true
  }

  user_data = "${base64encode("${data.template_file.user_data.rendered}")}"

  tags = "${merge(map("Name", "rancher"), var.cloud_tags)}"
}

resource "aws_key_pair" "rancher-key" {
  key_name   = "rancher-key"
  public_key = "${var.instance_public_key}"
}

resource "aws_route53_record" "rancher" {
  name    = "${var.domain_name}"
  type    = "A"
  zone_id = "${var.route53_zone_id}"

  alias {
    name                   = "${aws_lb.rancher_lb.dns_name}"
    zone_id                = "${aws_lb.rancher_lb.zone_id}"
    evaluate_target_health = true
  }
}
