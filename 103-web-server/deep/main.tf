terraform {
    required_version = ">=1.0.0, <2.0.0"

    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 6.0"
        }
    }
}

provider "aws" {
    region = "ap-northeast-2" # seoul
}

resource "aws_instance" "ubuntu" {
    ami = "ami-0bc151a94289adb52"
    instance_type = "t3.micro"
    tags ={
        Name ="tf-ubuntu-web"
    }
    user_data_replace_on_change = true
    user_data= file("${path.module}/userdata.sh")

    vpc_security_group_ids = [aws_security_group.tf-ubuntu-web-sg.id]
}

resource "aws_security_group" "tf-ubuntu-web-sg"{
    name= "tf-ubuntu-web-sg"
    description = "Allow HTTP inbound traffic"
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
}