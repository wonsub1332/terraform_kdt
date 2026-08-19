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

variable "image_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}

variable "instance_type" {
  description = "Type of EC2 instance"
  type = string
}

variable "key_name" {
  description = "Name of the key pair to use for SSH access"
  type        = string
}

variable "server_port" {
  description = "port will use for HTTP requests"
  type        = number
}

variable "security_group_name" {
  description = "Name of SG"
  type        = string
}

variable "enable_monitoring" {
  description = "Enable detailed monitoring for the EC2 instance"
  type        = bool
}

variable "http_cidr_blocks" {
  description = "CIDR blocks allowed for HTTP access"
  type        = list(string)
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
}

resource "aws_instance" "web" {
  ami                    = var.image_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.web.id]
  monitoring             = var.enable_monitoring

  key_name = var.key_name
  user_data_replace_on_change = true
  user_data              = <<-EOF
        #!/bin/bash
        yum -y install httpd 
        sed -i 's/Listen 80/Listen ${var.server_port}/' /etc/httpd/conf/httpd.conf
        systemctl enable httpd
        systemctl restart httpd
        echo '<html><h1>Hello From Your Linux Web Server running on port ${var.server_port} </h1></html>' > /var/www/html/index.html
        EOF

  tags = {
    Name = "tf-web"
  }
}

resource "aws_security_group" "web" {
  name        = var.security_group_name
  description = "Allow HTTP inbound traffic"

  ingress {
    description = "HTTP from VPC"
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = var.http_cidr_blocks
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

  lifecycle {
    create_before_destroy = true
  }
}

output "public_ip"{
  value = "${aws_instance.web.public_ip}:${var.server_port}"
  description = "Public IP and port of the web server"
}

output "private_ip"{
  value = "${aws_instance.web.private_ip}"
  description = "Private IP of the web server"
}