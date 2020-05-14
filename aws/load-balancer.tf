resource "aws_lb_target_group_attachment" "rancher" {
  target_group_arn = "${aws_lb_target_group.rancher.arn}"
  target_id        = "${aws_instance.rancher.id}"
  port             = 8443
}

resource "aws_lb_target_group" "rancher" {
  name_prefix = "rnch-"
  port        = 8443
  protocol    = "HTTPS"

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
  certificate_arn   = "${var.rancher_create_cert ? join("",aws_iam_server_certificate.rancher_elb_cert.*.arn) : var.rancher_elb_cert_arn}"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.rancher.arn}"
  }
}

resource "aws_s3_bucket" "rancher_lb_access_logs" {
  count         = "${var.rancher_lb_access_logs_bucket_create ? 1 : 0}"
  bucket        = "${var.rancher_lb_access_logs_bucket}"
  acl           = "private"
  force_destroy = true

  lifecycle_rule {
    enabled = true

    expiration {
      days = 10
    }
  }

  tags = "${merge(map("Name", "${var.rancher_lb_access_logs_bucket}"), var.cloud_tags)}"
}

data "aws_elb_service_account" "default" {}

data "aws_caller_identity" "default" {}

resource "aws_s3_bucket_policy" "rancher_lb_access_logs" {
  bucket = "${aws_s3_bucket.rancher_lb_access_logs.bucket}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "${data.aws_elb_service_account.default.arn}"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${var.rancher_lb_access_logs_bucket}/${var.rancher_lb_access_logs_prefix}/AWSLogs/${data.aws_caller_identity.default.account_id}/*"
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::${var.rancher_lb_access_logs_bucket}/${var.rancher_lb_access_logs_prefix}/AWSLogs/${data.aws_caller_identity.default.account_id}/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "arn:aws:s3:::${var.rancher_lb_access_logs_bucket}"
    }
  ]
}
EOF
}

# load balancer
resource "aws_lb" "rancher_lb" {
  name_prefix        = "rnch-"
  subnets            = ["${var.vpc_alb_subnet_ids}"]
  security_groups    = ["${concat(list(aws_security_group.rancher_elb.id), var.alb_security_groups)}"]
  load_balancer_type = "application"
  idle_timeout       = "${var.alb_idle_timeout}"

  access_logs {
    enabled         = "${var.rancher_lb_access_logs_enabled}"
    bucket          = "${var.rancher_lb_access_logs_bucket}"
    prefix          = "${var.rancher_lb_access_logs_prefix}"
  }

  tags = "${merge(map("Name", "rancher"), var.cloud_tags)}"
}
