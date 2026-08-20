resource "aws_lb" "alb" {
  name               = "final-alb"
  load_balancer_type = "application"
  subnets            = [aws_subnet.pub_a.id, aws_subnet.pub_c.id]
  security_groups    = [aws_security_group.alb_sg.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: page not found\n"
      status_code  = 404
    }
  }
}

resource "aws_lb_listener_rule" "lb_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100
  condition {
    path_pattern {
      values = ["*"]
    }
  }
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target.arn
  }
}
resource "aws_lb_target_group" "lb_target" {
  name     = "alb-targetgroup"
  port     = var.server_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.final_vpc.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}