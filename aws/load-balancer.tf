resource "aws_lb_target_group_attachment" "rancher" {
  target_group_arn = "${aws_lb_target_group.rancher.arn}"
  target_id        = "${aws_instance.rancher.id}"
  port             = 8443
}

resource "aws_lb_target_group" "rancher" {
  name     = "rancher-target-group"
  port     = 8443
  protocol = "HTTPS"

  vpc_id = "${var.vpc_id}"

  tags = "${merge(map("Name", "rancher"), var.cloud_tags)}"
}

resource "aws_lb_listener" "rancher_http" {
  load_balancer_arn = "${aws_lb.rancher_lb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "rancher_https" {
  load_balancer_arn = "${aws_lb.rancher_lb.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "${aws_iam_server_certificate.rancher_elb_cert.arn}"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.rancher.arn}"
  }
}

# load balancer
resource "aws_lb" "rancher_lb" {
  name               = "rancher-elb"
  subnets            = ["${var.vpc_subnet_ids}"]
  security_groups    = ["${concat(list(aws_security_group.rancher_elb.id), var.security_groups)}"]
  load_balancer_type = "application"

  tags = "${merge(map("Name", "rancher"), var.cloud_tags)}"
}
