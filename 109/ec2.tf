resource "aws_key_pair" "mykey" {
  key_name   = var.key_name
  public_key = file("${path.module}/${var.key_name}.pub")
}

resource "aws_security_group" "web" {
  description = var.instance_sercurity_group_name
  vpc_id      = aws_vpc.main.id
  ingress {
    from_port   = var.server_port
    to_port     = var.server_port
    protocol    = "tcp"
    cidr_blocks = var.http_cidr_blocks
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "web_pub" {
  ami                    = coalesce(data.aws_ami.al2023.image_id)
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.web.id]
  subnet_id              = aws_subnet.pub_c.id
  key_name               = aws_key_pair.mykey.key_name

  user_data_replace_on_change = true
  user_data                   = templatefile("${path.module}/userdata.tftpl",{ port_number = var.server_port,ep=aws_db_instance.tf-db.endpoint })

  tags = {
    Name = "tf-web-pub"
  }
}

resource "aws_instance" "web_pri" {
  ami                    = coalesce(data.aws_ami.al2023.image_id)
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.web.id]
  subnet_id              = aws_subnet.pri_c.id
  key_name               = aws_key_pair.mykey.key_name

  user_data_replace_on_change = true
  user_data                   = templatefile("${path.module}/userdata.tftpl", { port_number = var.server_port,ep=aws_db_instance.tf-db.endpoint })

  tags = {
    Name = "tf-web-pri"
  }
  depends_on = [ aws_nat_gateway.gw_c ]
}