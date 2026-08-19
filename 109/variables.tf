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

variable "key_name" {
  type = string
}

variable "image_id" {
  type    = string
  default = ""
}
variable "instance_type" {
  type    = string
  default = "t3.micro"
}
variable "server_port" {
  type    = number
  default = 80
}
variable "instance_sercurity_group_name" {
  type    = string
  default = "allow_http_ssh_instance"
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

variable "db_security_group_name"{
  type = string
  default = "allow_mysql_db"
}
variable "db_password" {
  type = string
  sensitive = true
}