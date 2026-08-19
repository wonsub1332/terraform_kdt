output "public_ec2" {
  description = "Public EC2 information"

  value = {
    public_ip  = aws_instance.web_image_server.public_ip
    private_ip = aws_instance.web_image_server.private_ip
    web_url    = "http://${aws_instance.web_image_server.public_ip}:${var.server_port}"
  }
}


output "db_end" {
  description = "db information"

  value = {
    end_point = aws_db_instance.final_db.endpoint
  }
}

output "alb_dns_name" {
  description = "domain name of the LB"
  value       = aws_lb.alb.dns_name
}