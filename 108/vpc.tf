# =========================================================
# VPC
# =========================================================

resource "aws_vpc" "main" {
    # VPC 전체 네트워크 대역
    cidr_block = "10.0.0.0/16"

    # EC2 인스턴스가 Public DNS Hostname을 가질 수 있도록 설정
    enable_dns_hostnames = true

    tags = {
      Name = "tf-vpc"
    }
}


# =========================================================
# Internet Gateway
# =========================================================

resource "aws_internet_gateway" "main" {
    # 생성한 VPC에 Internet Gateway 연결
    # Public Subnet의 인터넷 통신에 사용
    vpc_id = aws_vpc.main.id

    tags = {
        Name = "tf-igw"
    }
}


# =========================================================
# Public Subnet
# =========================================================

resource "aws_subnet" "pub_a" {
    # Subnet이 위치할 VPC
    vpc_id = aws_vpc.main.id

    # Public Subnet A의 IP 대역
    cidr_block = "10.0.0.0/24"

    # 서울 리전의 ap-northeast-2a AZ에 생성
    availability_zone = "ap-northeast-2a"

    # 이 Subnet에서 생성되는 EC2에 Public IP 자동 할당
    map_public_ip_on_launch = true

    tags = {
        Name = "tf-subnet-public1-ap-northeast-2a"
    }
}

resource "aws_subnet" "pub_c" {
    # Subnet이 위치할 VPC
    vpc_id = aws_vpc.main.id

    # Public Subnet C의 IP 대역
    cidr_block = "10.0.2.0/24"

    # 서울 리전의 ap-northeast-2c AZ에 생성
    availability_zone = "ap-northeast-2c"

    # 이 Subnet에서 생성되는 EC2에 Public IP 자동 할당
    map_public_ip_on_launch = true

    tags = {
        Name = "tf-subnet-public1-ap-northeast-2c"
    }
}


# =========================================================
# Public Route Table
# =========================================================

resource "aws_route_table" "pub" {
    # Route Table이 속할 VPC
    vpc_id = aws_vpc.main.id

    # 목적지가 인터넷(0.0.0.0/0)인 트래픽을
    # Internet Gateway로 전달
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
    }

    tags = {
        Name = "tf-rtb-public"
    }
}


# =========================================================
# Route Table Association
# =========================================================

resource "aws_route_table_association" "pub_a" {
    # Public Subnet A에 Public Route Table 연결
    subnet_id      = aws_subnet.pub_a.id
    route_table_id = aws_route_table.pub.id
}

resource "aws_route_table_association" "pub_c" {
    # Public Subnet C에 Public Route Table 연결
    subnet_id      = aws_subnet.pub_c.id
    route_table_id = aws_route_table.pub.id
}

# =========================================================
# Private Subnet
# =========================================================


resource "aws_subnet" "pri_a"{
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "ap-northeast-2a"
    tags = {
      Name="tf-subnet-private1-ap-northeast-2a"
    }
}

resource "aws_subnet" "pri_c"{
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.3.0/24"
    availability_zone = "ap-northeast-2c"
    tags = {
      Name="tf-subnet-private2-ap-northeast-2c"
    }
}

# =========================================================
# Private Route Table
# =========================================================

resource "aws_route_table" "pri_a"{
    vpc_id = aws_vpc.main.id
    tags = {
        Name="tf-rtb-private1-ap-northeast-2a"
    }
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.gw_a.id
    }
}
resource "aws_route_table" "pri_c"{
    vpc_id = aws_vpc.main.id
    tags = {
        Name="tf-rtb-private2-ap-northeast-2c"
    }
    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.gw_c.id
    }
}
# =========================================================
# Route Table Association
# =========================================================

resource "aws_route_table_association" "pri_a"{
    subnet_id = aws_subnet.pri_a.id
    route_table_id = aws_route_table.pri_a.id
}
resource "aws_route_table_association" "pri_c"{
    subnet_id = aws_subnet.pri_c.id
    route_table_id = aws_route_table.pri_c.id
}

# =========================================================
# 탄력적 IP
# =========================================================

resource "aws_eip" "pub_a"{
    domain = "vpc"
    depends_on = [ aws_internet_gateway.main ]

    tags = {
      Name="tf-nat-public1-ap2a"
    }
}
resource "aws_eip" "pub_c"{
    domain = "vpc"
    depends_on = [ aws_internet_gateway.main ]

    tags = {
      Name="tf-nat-public1-ap2c"
    }
}
# =========================================================
# NAT GATEWAY
# =========================================================

resource "aws_nat_gateway" "gw_a"{
    allocation_id = aws_eip.pub_a.id
    subnet_id = aws_subnet.pub_a.id
    tags = {
     Name = "tf-nat-2a"
    }
    depends_on = [ aws_eip.pub_a ]
}

resource "aws_nat_gateway" "gw_c"{
    allocation_id = aws_eip.pub_c.id
    subnet_id = aws_subnet.pub_c.id
    tags = {
     Name = "tf-nat-2c"
    }
    depends_on = [ aws_eip.pub_c ]
}