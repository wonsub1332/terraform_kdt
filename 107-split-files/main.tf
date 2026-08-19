# RSA Key Pair 생성 (Windows EC2까지 고려하면 RSA가 가장 무난)
# mkdir -p keys
# ssh-keygen -t rsa -b 2048 -m PEM -f ./keys/mykey -N ""

resource "aws_key_pair" "mykey" {
  key_name   = var.key_name
  public_key = file("${path.module}/mykey.pub")
}

resource "aws_launch_template" "web" {
  name                   = "lt-web"
  image_id               = coalesce(var.image_id, data.aws_ami.al2023.id)
  instance_type          = var.instance_type
  key_name               = aws_key_pair.mykey.key_name
  vpc_security_group_ids = [aws_security_group.web.id]

  user_data = base64encode(
    templatefile("${path.module}/userdata.tftpl", {
      port_number = var.server_port
    })
  )

  monitoring {
    enabled = var.enable_monitoring
  }
}

resource "aws_security_group" "web" {
  name        = var.web_security_group_name
  description = "Allow HTTP inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP from VPC"
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    # cidr_blocks = var.http_cidr_blocks
    security_groups = [
      aws_security_group.alb.id # ALB에서만 접근 허용
    ]
  }

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.web_security_group_name
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "alb" {
  name        = var.alb_security_group_name
  description = "Allow HTTP inbound traffic to ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP from Internet"
    from_port   = var.alb_listener_port
    to_port     = var.alb_listener_port
    protocol    = "tcp"
    cidr_blocks = var.http_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.alb_security_group_name
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web" {
  name_prefix         = "asg-web-"
  max_size            = 4
  min_size            = 2
  desired_capacity    = 2
  vpc_zone_identifier = data.aws_subnets.default.ids

  target_group_arns = [
    aws_lb_target_group.web.arn
  ]
  health_check_type         = "ELB" # 초기에는 "EC2", 서버 서비스 정상화 확인 후에 "ELB"로 지정을 추천. (ELB는 Target Group의 Health Check에 따라 인스턴스를 자동 교체하므로 오류 찾기가 어려움)
  health_check_grace_period = 120   # 기본값은 300초, 5분. 60초로 줄임. (ASG에서 인스턴스 시작 후, 120초 동안 Health Check를 무시하고 Warmup 상태로 둠)

  launch_template {
    id      = aws_launch_template.web.id
    version = aws_launch_template.web.latest_version #version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 60
    }
  }

  tag {
    key                 = "Name"
    value               = "tf-asg-web"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb" "alb" {
  name               = var.alb_name
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.aws_subnets.default.ids

  tags = {
    Name = var.alb_name
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = var.alb_listener_port
  protocol          = "HTTP"

  # By default, return a simple 404 page
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "404: Page Not Found\n"
      status_code  = 404
    }
  }
}

resource "aws_lb_target_group" "web" {
  name_prefix = "tg-web"
  target_type = "instance"
  port        = var.server_port
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.default.id

  deregistration_delay = 60 # 기본값은 300초, 5분. 60초로 줄임. (ASG에서 인스턴스 종료 시, 60초 동안 요청을 처리 후 종료)

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 15
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "tg-web"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_listener_rule" "web" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  condition {
    path_pattern {
      values = ["/*"]
    }
  }

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web.arn
  }
}

