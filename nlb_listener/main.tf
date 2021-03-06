resource "aws_lb_target_group" "default" {
  count = var.default_target_group_arn == "" ? 1 : 0

  # target group name can't be longer than 32 chars, and terraform autogenerated name is 26 characters long
  # so `name_prefix` can't be longer than 6 characters. Resource is tagged in any case for a clear identification in AWS
  name_prefix = var.name_prefix

  port                 = var.target_port
  protocol             = "TCP"
  vpc_id               = var.vpc_id
  deregistration_delay = var.target_deregistration_delay
  target_type          = var.target_type

  health_check {
    interval            = var.target_health_interval
    healthy_threshold   = var.target_health_threshold
    unhealthy_threshold = var.target_health_threshold
    protocol            = "TCP"
  }

  tags = merge(
    var.tags,
    {
      "Name"        = "${var.project}-${var.environment}-${var.name_prefix}-target-group"
      "Environment" = var.environment
      "Project"     = var.project
    },
  )
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = var.nlb_arn
  port              = var.ingress_port
  protocol          = var.listener_protocol
  certificate_arn   = var.certificate_arn

  default_action {
    # Using join with resource.* as workaround for https://github.com/hashicorp/hil/issues/50
    target_group_arn = var.default_target_group_arn == "" ? join(" ", aws_lb_target_group.default.*.arn) : var.default_target_group_arn
    type             = "forward"
  }
}
