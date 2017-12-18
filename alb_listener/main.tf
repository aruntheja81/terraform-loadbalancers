resource "aws_alb_target_group" "default" {
  count = "${var.default_target_group_arn == "" ? 1 : 0}"

  # target group name can't be longer than 32 chars, and terraform autogenerated name is 26 characters long
  # so `name_prefix` can't be longer than 6 characters. Resource is tagged in any case for a clear identification in AWS
  name_prefix = "def-"

  port                 = "${var.target_port}"
  protocol             = "${var.target_protocol}"
  vpc_id               = "${var.vpc_id}"
  deregistration_delay = "${var.target_deregistration_delay}"
  stickiness           = ["${var.target_stickiness}"]

  health_check {
    interval            = "${var.target_health_interval}"
    path                = "${var.target_health_path}"
    timeout             = "${var.target_health_timeout}"
    healthy_threshold   = "${var.target_health_healthy_threshold}"
    unhealthy_threshold = "${var.target_health_unhealthy_threshold}"
    matcher             = "${var.target_health_matcher}"
    protocol            = "${var.target_health_protocol}"
  }

  tags = "${merge("${var.tags}",
    map("Name", "${var.project}-${var.environment}-${var.name}-default",
      "Environment", "${var.environment}",
      "Project", "${var.project}"))
  }"
}

resource "aws_alb_listener" "http" {
  count             = "${var.enable_http_listener}"
  load_balancer_arn = "${aws_alb.alb.arn}"
  port              = "${var.http_port}"
  protocol          = "HTTP"

  default_action {
    # Using join with resource.* as workaround for https://github.com/hashicorp/hil/issues/50
    target_group_arn = "${var.default_target_group_arn == "" ? join(" ", aws_alb_target_group.default.*.arn) : var.default_target_group_arn}"
    type             = "forward"
  }
}

resource "aws_alb_listener" "https" {
  count             = "${var.enable_https_listener}"
  load_balancer_arn = "${aws_alb.alb.arn}"
  port              = "${var.https_port}"
  protocol          = "HTTPS"
  certificate_arn   = "${var.https_certificate_arn}"

  default_action {
    # Using join with resource.* as workaround for https://github.com/hashicorp/hil/issues/50
    target_group_arn = "${var.default_target_group_arn == "" ? join(" ", aws_alb_target_group.default.*.arn) : var.default_target_group_arn}"
    type             = "forward"
  }
}