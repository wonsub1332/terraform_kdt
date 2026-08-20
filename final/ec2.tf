resource "aws_key_pair" "mykey" {
  key_name   = var.key_name
  public_key = file("${path.module}/${var.key_name}.pub")
}
resource "aws_instance" "web_image_server" {
  ami                    = data.aws_ami.al2023.image_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.image_sg.id, aws_security_group.ssh_sg.id]
  subnet_id              = aws_subnet.pub_c.id
  key_name               = aws_key_pair.mykey.key_name
  tags = {
    Name = "web_image_server"
  }
}