locals {
  listeners = [{
    instance_port      = var.instance_port
    instance_protocol  = var.instance_protocol
    lb_port            = var.lb_port
    lb_protocol        = var.lb_protocol
  },
  {
    instance_port      = var.instance_ssl_port
    instance_protocol  = var.instance_ssl_protocol
    lb_port            = var.lb_ssl_port
    lb_protocol        = var.lb_ssl_protocol
    ssl_certificate_id = var.ssl_certificate_id
  }]
}

resource "aws_elb" "elb" {
  name                        = "${var.project}-${var.environment}-${var.name}"
  subnets                     = var.subnets
  internal                    = var.internal
  cross_zone_load_balancing   = true
  idle_timeout                = var.idle_timeout
  connection_draining         = var.connection_draining
  connection_draining_timeout = var.connection_draining_timeout
  security_groups             = [aws_security_group.elb.id]

  dynamic "access_logs" {
    for_each = var.access_logs_enabled ? [var.access_logs_enabled] : []
    content {
      bucket        = var.access_logs_bucket
      bucket_prefix = var.access_logs_bucket_prefix
      interval      = var.access_logs_interval
      enabled       = var.access_logs_enabled
    }
  }

  dynamic "listener" {
    for_each = var.ssl_certificate_id == null ? [local.listeners[0]] :local.listeners
    content {
      instance_port      = lookup(listener.value, "instance_port", null)
      instance_protocol  = lookup(listener.value, "instance_protocol", null )
      lb_port            = lookup(listener.value, "lb_port", null )
      lb_protocol        = lookup(listener.value, "lb_protocol", null )
      ssl_certificate_id = lookup(listener.value, "ssl_certificate_id", null )
    }
  }

  dynamic "listener" {
    for_each = var.custom_listeners
    content {
      instance_port      = lookup(listener.value, "instance_port", null)
      instance_protocol  = lookup(listener.value, "instance_protocol", null )
      lb_port            = lookup(listener.value, "lb_port", null )
      lb_protocol        = lookup(listener.value, "lb_protocol", null )
      ssl_certificate_id = lookup(listener.value, "ssl_certificate_id", null )
    }
  }

  health_check {
    healthy_threshold   = var.healthy_threshold
    unhealthy_threshold = var.unhealthy_threshold
    timeout             = var.health_timeout
    target              = var.health_target
    interval            = var.health_interval
  }

  tags = {
    Name        = "${var.project}-${var.environment}-${var.name}"
    Environment = var.environment
    Project     = var.project
  }
}
