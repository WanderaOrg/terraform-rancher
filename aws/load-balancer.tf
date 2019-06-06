resource "aws_lb_target_group_attachment" "test" {
  target_group_arn = "${aws_lb_target_group.rancher_target_group.arn}"
  target_id        = "${aws_instance.rancher.id}"
  port             = 443
}

resource "aws_lb_target_group" "rancher_target_group" {
  name     = "rancher-target-group"
  port     = 443
  protocol = "HTTPS"

  vpc_id   = "${var.vpc_id}"
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
    target_group_arn = "${aws_lb_target_group.rancher_target_group.arn}"
  }
}

# load balancer
resource "aws_lb" "rancher_lb" {
  name               = "rancher-elb"
  subnets = ["${var.vpc_subnet_ids}"]
  security_groups = ["${aws_security_group.rancher_elb.id}", "${var.security_groups}"]
  load_balancer_type = "application"

  tags = {
    Name = "rancher-elb"
  }
}
