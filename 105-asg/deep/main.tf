terraform {
    
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.3.0"
}
provider "aws" {
  region = "ap-northeast-2" # Asia Pacific (Seoul) region
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
variable "security_group_name" {
  description = "The name of the security group"
  type        = string
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

data "aws_vpc" "default"{
    default = true
}
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}
data "aws_ami" "latest_ubuntu" {
  most_recent = true
  owners = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
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
resource "aws_security_group" "web"{
    name=var.security_group_name

    ingress{
        from_port = var.server_port
        to_port = var.server_port
        protocol = "tcp"
        cidr_blocks = var.http_cidr_blocks
    }
    ingress{
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
    lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_template" "lt" {
    name_prefix = "lt-web-"
    image_id = coalesce(var.image_id, data.aws_ami.latest_ubuntu.id)
    instance_type = var.instance_type

    key_name = var.key_name
    vpc_security_group_ids = [aws_security_group.web.id]

    update_default_version = true
    user_data = base64encode(
        templatefile("${path.module}/userdata.tftpl",{port_number=var.server_port})
    )  
}
resource "aws_autoscaling_group" "web"{
  name_prefix = "web-"
  min_size = 2
  max_size = 4
  desired_capacity = 2
  vpc_zone_identifier = data.aws_subnets.default.ids

  launch_template {
    id = aws_launch_template.lt.id
    version = aws_launch_template.lt.latest_version


  }
  tag {
    key                 = "Name"
    value               = "tf-asg-ubuntu-web"
    propagate_at_launch = true
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      instance_warmup        = 60
    }
  }
}