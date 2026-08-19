resource "aws_security_group" "web_sg" {
  vpc_id      = aws_vpc.final_vpc.id
  description = "allow_http_instance"
  tags = {
    Name = "web_sg"
  }
  ingress {
    from_port = var.server_port
    to_port   = var.server_port
    #security_groups = [aws_security_group.alb_sg.id]
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_security_group" "ssh_sg" {
  vpc_id      = aws_vpc.final_vpc.id
  description = "allow_ssh_instance"
  tags = {
    Name = "ssh_sg"
  }
  ingress {
    from_port   = 22
    to_port     = 22
    cidr_blocks = var.ssh_cidr_blocks
    protocol    = "tcp"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_security_group" "DB_sg" {
  vpc_id      = aws_vpc.final_vpc.id
  description = "DB security group"
  tags = {
    Name = "db_sg"
  }
  ingress {
    from_port       = 3306
    to_port         = 3306
    security_groups = [aws_security_group.web_sg.id]
    protocol        = "tcp"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "alb_sg" {
  vpc_id      = aws_vpc.final_vpc.id
  description = "alb security group"
  tags = {
    Name = "alb_sg"
  }
  ingress {
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  lifecycle {
    create_before_destroy = true
  }
}