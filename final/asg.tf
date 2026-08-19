resource "aws_launch_template" "web_lt" {
  name                   = "web_lt"
  image_id               = data.aws_ami.web_ami.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.mykey.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  update_default_version = true
  monitoring {
    enabled = var.enable_monitoring
  }

  user_data = base64encode(
    templatefile("${path.module}/userdata.tftpl", {
      port_number = var.server_port
    })
  )
}

resource "aws_autoscaling_group" "web_asg" {
  name_prefix = "asg-web-"
  launch_template {
    id      = aws_launch_template.web_lt.id
    version = aws_launch_template.web_lt.latest_version
  }
  vpc_zone_identifier = [aws_subnet.pri_a.id, aws_subnet.pri_c.id]
  target_group_arns   = [aws_lb_target_group.lb_target.arn]
  health_check_type   = "ELB"
  min_size            = var.asg_info.min
  max_size            = var.asg_info.max
  desired_capacity    = var.asg_info.desired

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 60
    }
  }
}