terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-2" # Asia Pacific (Seoul) region
}

#============================ Varuable ====================================

variable "web_security_group_name" {
    description = "The name of the security group for EC2 Instance"
    type = string
    default = "allow_http_ssh_instance"  
}
variable "alb_security_group_name" {
    description = "The name of the security group for the ALB"
    type = string
    default = "allow_http_alb"
}
variable "image_id" {
  description = "The AMI ID to use for the instance"
  type        = string
  default     = null
}
variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
}
variable "instance_type" {
  description = "The type of instance to use"
  type        = string
}
variable "key_name" {
  description = "The name of the key pair to use for SSH access"
  type        = string
}
variable "enable_monitoring" {
  description = "Whether to enable detailed monitoring for the instance"
  type        = bool 
}
variable "http_cidr_blocks" {
    type = list(string)
}
variable "ssh_cidr_blocks"{
    type = list(string)
}
variable "alb_name"{
    type = string
}
#============================ data ====================================
data "aws_vpc" "default" {
  default = true
}
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
data "aws_ami" "latest_amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

#============================ Resource ====================================

resource "aws_security_group" "web"{
    name = var.web_security_group_name
    description = "Allow HTTP and SSH inbound traffic"

    ingress {
        from_port = var.server_port
        to_port = var.server_port
        protocol = "tcp"
        cidr_blocks = var.http_cidr_blocks
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = var.ssh_cidr_blocks
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
      Name=var.web_security_group_name
    }
    lifecycle {
      create_before_destroy = true
    }
}
resource "aws_security_group" "alb"{
    name = var.alb_security_group_name
    description = "Allow HTTP inbound traffic"

    ingress {
        description = "HTTP from VPC"
        from_port = var.server_port
        to_port = var.server_port
        protocol = "tcp"
        cidr_blocks = var.http_cidr_blocks
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
     Name=var.alb_security_group_name 
    }
    lifecycle {
      create_before_destroy = true
    }
}
resource "aws_launch_template" "web" {
  name_prefix            = "lt-web-"
  image_id               = coalesce(var.image_id, data.aws_ami.latest_amazon_linux.id)
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.web.id]
  update_default_version = true
  monitoring {
    enabled = var.enable_monitoring
  }


  user_data = base64encode(
    templatefile("${path.module}/userdata.tftpl", {
      server_port = var.server_port
    })
  )

}
resource "aws_lb" "alb"{
    name = var.alb_name
    load_balancer_type = "application"
    subnets = data.aws_subnets.default.ids
    security_groups = [ aws_security_group.alb.id ]
}

resource "aws_lb_listener" "http"{
    load_balancer_arn = aws_lb.alb.arn
    port = 80
    protocol = "HTTP"
    default_action {
      type = "fixed-response"

      fixed_response {
        content_type = "text/plain"
        message_body = "404: page not found\n"
        status_code = 404
      }
    }
}

resource "aws_lb_listener_rule" "asg" {
    listener_arn = aws_lb_listener.http.arn
    priority = 100
    condition {
      path_pattern {
        values = ["*"]
      }
    }
    action {
      type = "forward"
      target_group_arn = aws_lb_target_group.asg.arn
    }
}

resource "aws_lb_target_group" "asg"{
    name = var.alb_name
    port = 80
    protocol = "HTTP"
    vpc_id = data.aws_vpc.default.id

    health_check {
      path = "/"
      protocol = "HTTP"
      matcher = "200"
      interval = 15
      timeout = 3
      healthy_threshold = 2
      unhealthy_threshold = 2
    }
}

resource "aws_autoscaling_group" "web" {
  name = "asg-web-"
  launch_template {
    id=aws_launch_template.web.id
    version = "$Latest"
  }
  vpc_zone_identifier = data.aws_subnets.default.ids
  
  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"
  
  min_size = 2
  max_size = 4
}

#============================ output ====================================

output "alb_dns_name"{
    description = "domain name of the LB"
    value = aws_lb.alb.dns_name
}