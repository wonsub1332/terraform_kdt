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

resource "aws_instance" "web" {
  ami                    = "ami-04ad6ded6cff6b818" # Amazon Linux 2023 (ap-northeast-2)
  instance_type          = "t3.micro"
  vpc_security_group_ids = [aws_security_group.web.id]
  user_data              = <<-EOF
        #!/bin/bash
        yum -y install httpd 
        systemctl enable httpd
        systemctl restart httpd
        echo '<html><h1>Hello From Your Linux Web Server!</h1></html>' > /var/www/html/index.html
        EOF

  tags = {
    Name = "tf-web"
  }
}

resource "aws_security_group" "web" {
  name        = "allow_http"
  description = "Allow HTTP inbound traffic"

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
