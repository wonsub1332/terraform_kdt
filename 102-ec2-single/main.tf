provider "aws" {
  region = "ap-northeast-2" # seoul
}

resource "aws_instance" "web" {
  ami           = "ami-04ad6ded6cff6b818" 

  instance_type ="t3.micro"
  
  tags = {
    Name = "tf-web"
  }
  security_groups = [aws_security_group.web_sg.name]

}

resource "aws_security_group" "web_sg" {
  name= "web_sg"
  description = "Allow HTTP inbound traffic"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "HTTP"
    ip_ranges = ["0.0.0.0/0"]
  }
}