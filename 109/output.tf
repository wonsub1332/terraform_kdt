output "public_ec2" {
  description = "Public EC2 information"

  value = {
    public_ip  = aws_instance.web_pub.public_ip
    private_ip = aws_instance.web_pub.private_ip
    web_url    = "http://${aws_instance.web_pub.public_ip}:${var.server_port}"
  }
}

output "private_ec2" {
  description = "Private EC2 information"

  value = {
    private_ip = aws_instance.web_pri.private_ip
    web_url    = "http://${aws_instance.web_pri.private_ip}:${var.server_port}"
  }
}

output "db_end" {
  description = "db information"

  value = {
    end_point= aws_db_instance.tf-db.endpoint
    web_url    = "${aws_db_instance.tf-db.endpoint}"
  }
}