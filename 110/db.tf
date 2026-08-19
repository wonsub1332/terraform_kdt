resource "aws_security_group" "db_sg"{
    vpc_id = aws_vpc.main.id
    ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        security_groups = [aws_security_group.web_sg.id]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name=var.db_security_group_name
    }
}

resource "aws_db_subnet_group" "lab-db"{
    name = "main"
    subnet_ids = [aws_subnet.pri_a.id,aws_subnet.pri_c.id]
    tags = {
      Name = "Terraform DB subnet group"
    }
}

resource "aws_db_instance" "lab-db"{
    identifier = "lab-db"
    allocated_storage = 10
    engine = "mysql"
    engine_version = "8.0"
    instance_class = "db.t3.micro"
    db_name = "terraformdb"
    username = "master"
    password = var.db_password
    skip_final_snapshot = true
    db_subnet_group_name = aws_db_subnet_group.lab-db.name
    vpc_security_group_ids = [aws_security_group.db_sg.id]
    multi_az = true
}