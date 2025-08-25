resource "aws_security_group" "alb" {
  name_prefix = "${var.environment}-citrine-alb-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-citrine-alb-sg"
  })
}

resource "aws_lb" "main" {
  name               = "${var.environment}-citrine-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = var.enable_deletion_protection

  tags = merge(var.tags, {
    Name = "${var.environment}-citrine-alb"
  })
}

# Target Group for Citrine
resource "aws_lb_target_group" "citrine" {
  name        = "${var.environment}-citrine-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-citrine-tg"
  })
}

# Target Group for Directus
resource "aws_lb_target_group" "directus" {
  name        = "${var.environment}-directus-tg"
  port        = 8055
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/server/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }

  tags = merge(var.tags, {
    Name = "${var.environment}-directus-tg"
  })
}

# HTTP Listener (redirect to HTTPS only if certificate is provided)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  dynamic "default_action" {
    for_each = var.certificate_arn != "" ? [1] : []
    content {
      type = "redirect"

      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  dynamic "default_action" {
    for_each = var.certificate_arn == "" ? [1] : []
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.citrine.arn
    }
  }
}

# HTTPS Listener for Citrine (only if certificate is provided)
resource "aws_lb_listener" "https_citrine" {
  count = var.certificate_arn != "" ? 1 : 0

  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-2017-01"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.citrine.arn
  }
}

# HTTPS Listener Rule for Directus (only if certificate is provided)
resource "aws_lb_listener_rule" "directus" {
  count = var.certificate_arn != "" ? 1 : 0

  listener_arn = aws_lb_listener.https_citrine[0].arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.directus.arn
  }

  condition {
    path_pattern {
      values = ["/admin*", "/server*", "/auth*"]
    }
  }
}

# HTTPS Listener Rule for Citrine (default) (only if certificate is provided)
resource "aws_lb_listener_rule" "citrine" {
  count = var.certificate_arn != "" ? 1 : 0

  listener_arn = aws_lb_listener.https_citrine[0].arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.citrine.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}
