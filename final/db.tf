resource "aws_db_subnet_group" "final_db"{
    name = "main"
    subnet_ids = [aws_subnet.pri_a.id,aws_subnet.pri_c.id]
    tags = {
      Name="DB subnet group"
    }
}


resource "aws_db_instance" "final_db"{
    identifier = "final-db"
    allocated_storage = 10
    engine = var.db_info.engine
    engine_version = var.db_info.version
    instance_class = var.db_info.instance_class
    db_name = var.db_info.db_name
    username = var.db_info.username
    password = var.db_password
    skip_final_snapshot = true
    db_subnet_group_name = aws_db_subnet_group.final_db.name
    vpc_security_group_ids = [aws_security_group.DB_sg.id]
    multi_az = true
}
