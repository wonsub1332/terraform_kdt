variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type        = number
}

variable "alb_listener_port" {
  description = "The port the ALB will use for HTTP requests"
  type        = number
}

variable "web_security_group_name" {
  description = "The name of the security group for Web Servers"
  type        = string
}

variable "alb_security_group_name" {
  description = "The name of the security group for the ALB"
  type        = string
}

variable "image_id" {
  description = "The ID of the AMI to use for the instance"
  type        = string
  default     = null # If empty, the latest Amazon Linux 2023 AMI will be used
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

variable "alb_name" {
  description = "The name of the Application Load Balancer"
  type        = string
}

