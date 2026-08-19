data "aws_ami" "myami" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["lab-*"]
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

variable "common_tag" {
  description = "Common tag"
  type = map(string)
}