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

/*
resource "aws_instance" "web" {
  ami                         = var.image_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  monitoring                  = var.enable_monitoring
  vpc_security_group_ids      = [aws_security_group.web.id]
  user_data_replace_on_change = true
  user_data                   = <<-EOF
        #!/bin/bash
        yum -y install httpd 
        sed -i 's/Listen 80/Listen ${var.server_port}/' /etc/httpd/conf/httpd.conf
        systemctl enable httpd
        systemctl restart httpd
        echo '<html><h1>Hello From Your Linux Web Server running on port ${var.server_port}</h1></html>' > /var/www/html/index.html
        EOF

  tags = {
    Name = "tf-web"
  }
}
*/

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

resource "aws_key_pair" "instance_key" {
  key_name   = var.key_name
  public_key = file("${path.module}/${var.key_name}.pub")
}

resource "aws_launch_template" "web" {
  name_prefix            = "lt-web-"
  image_id               = coalesce(var.image_id, data.aws_ami.latest_amazon_linux.id)
  instance_type          = var.instance_type
  key_name               = aws_key_pair.instance_key.key_name
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

resource "aws_autoscaling_group" "web" {
  name_prefix      = "asg-web-"
  min_size         = 2
  max_size         = 4
  desired_capacity = 2

  

  vpc_zone_identifier = data.aws_subnets.default.ids

  launch_template {
    id      = aws_launch_template.web.id
    #version = "$Latest"
    version = aws_launch_template.web.latest_version
  }
  tag {
    key                 = "Name"
    value               = "tf-asg-web"
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


resource "aws_security_group" "web" {
  name        = var.security_group_name
  description = "Allow HTTP inbound traffic"
  vpc_id      = data.aws_vpc.default.id

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





variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
}

variable "security_group_name" {
  description = "The name of the security group"
  type        = string
}

variable "image_id" {
  description = "The ID of the AMI to use for the instance"
  type        = string
  default = "ami-04ad6ded6cff6b818"
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
  description = "Enable detailed monitoring for the instance"
  type        = bool
}

variable "http_cidr_blocks" {
  description = "The CIDR blocks to allow HTTP access from"
  type        = list(string)
}

variable "ssh_cidr_blocks" {
  description = "The CIDR blocks to allow SSH access from"
  type        = list(string)
}


/*
output "public_ip"{
  value = "${aws_instance.web.public_ip}:${var.server_port}"
  description = "Public IP and port of the web server"
}

output "private_ip"{
  value = "${aws_instance.web.private_ip}"
  description = "Private IP of the web server"
}
*/