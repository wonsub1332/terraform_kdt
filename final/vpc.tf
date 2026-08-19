# ========================== VPC ====================================

resource "aws_vpc" "final_vpc"{
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
    tags = {
        Name = "final-vpc"
    }
}

# ========================== IGW ====================================

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.final_vpc.id
    tags = {
        Name="final-igw"
    }
}
# ========================== Eip ====================================
resource "aws_eip" "nat_eip"{
    domain = "vpc"
    depends_on = [ aws_internet_gateway.igw ]
    tags = {
      Name="final-eip-a"
    }
}
# ========================== NAT ====================================

resource "aws_nat_gateway" "nat_a" {
    allocation_id = aws_eip.nat_eip.id
    subnet_id = aws_subnet.pub_a.id 
    depends_on = [ aws_eip.nat_eip ]
    tags = {
        Name="final-nat-a"
    }
}

# ========================== SUBNET ====================================

resource "aws_subnet" "pub_a"{
    vpc_id = aws_vpc.final_vpc.id
    cidr_block = "10.0.0.0/24"
    availability_zone = "ap-northeast-2a"
    map_public_ip_on_launch = true
    tags = {
      Name = "public-subnet-A"
    }
}
resource "aws_subnet" "pub_c"{
    vpc_id = aws_vpc.final_vpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "ap-northeast-2c"
    map_public_ip_on_launch = true
    tags = {
      Name = "public-subnet-C"
    }
}
resource "aws_subnet" "pri_a"{
    vpc_id = aws_vpc.final_vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "ap-northeast-2a"
    tags = {
      Name = "private-subnet-A"
    }
}
resource "aws_subnet" "pri_c"{
    vpc_id = aws_vpc.final_vpc.id
    cidr_block = "10.0.3.0/24"
    availability_zone = "ap-northeast-2c"
    tags = {
      Name = "private-subnet-C"
    }
}
# ========================== Route Table ====================================
resource "aws_route_table" "pub_rtb" {
  vpc_id = aws_vpc.final_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  depends_on = [ aws_internet_gateway.igw ]

  tags = {
    Name="final-rtb-public"
  }
}

resource "aws_route_table" "pri_rtb_a"{
    vpc_id = aws_vpc.final_vpc.id
    depends_on = [ aws_nat_gateway.nat_a ]
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat_a.id
    }
    tags = {
        Name="final-rtb-private-a"
    }
}
resource "aws_route_table" "pri_rtb_c"{
    vpc_id = aws_vpc.final_vpc.id
    depends_on = [ aws_nat_gateway.nat_a ]
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.nat_a.id
    }
    tags = {
        Name="final-rtb-private-c"
    }
}

# =============== Route Table Association =================================
resource "aws_route_table_association" "pub_a"{
    subnet_id = aws_subnet.pub_a.id
    route_table_id = aws_route_table.pub_rtb.id
}
resource "aws_route_table_association" "pub_c"{
    subnet_id = aws_subnet.pub_c.id
    route_table_id = aws_route_table.pub_rtb.id
}
resource "aws_route_table_association" "pri_a"{
    subnet_id = aws_subnet.pri_a.id
    route_table_id = aws_route_table.pri_rtb_a.id
}
resource "aws_route_table_association" "pri_c"{
    subnet_id = aws_subnet.pri_c.id
    route_table_id = aws_route_table.pri_rtb_c.id
}