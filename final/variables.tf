data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
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

data "aws_ami" "web_ami"{
  most_recent = true
  owners = [ "self" ]
  filter {
    name = "name"
    values = ["web-*"]
  }
}

variable "server_port" {
  type    = number
  default = 80
}
variable "image_id" {
  type    = string
  default = ""
}
variable "instance_type" {
  type    = string
  default = "t3.micro"
}
variable "key_name" {
  type = string
}
variable "ssh_cidr_blocks"{
    type = list(string)
    default = [ ]
}
variable "db_info"{
  type = map(string)
  default = {
    engine = "mysql"
    version="8.0"
    instance_class = "db.t3.micro"
    db_name="terraformdb"
    username="master"
  }
}
variable "db_password" {
  type = string
  sensitive = true
  default = "tf-password"
}

variable "enable_monitoring" {
  type = bool
  default = false
}
variable "asg_info" {
  type = map(number)
  default = {
    min = 2
    max = 4
    desired = 2
  }
}