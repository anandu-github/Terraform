terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# VPC Creation
resource "aws_vpc" "my-vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "today-vpc"
  }
}

# create public subnet
resource "aws_subnet" "pub-subnet" {
  vpc_id     = aws_vpc.my-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "public-subnet"
  }
}

#create private subnet
resource "aws_subnet" "pri-subnet" {
  vpc_id     = aws_vpc.my-vpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "private-subnet"
  }
}

#create internet gateway (igw)
resource "aws_internet_gateway" "my-igw" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "tigw"
  }
}


# Create public route table
resource "aws_route_table" "pub-route-table" {
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my-igw.id
   # subnet_id = aws_subnet.pub-subnet.id   
  }

  tags = {
    Name = "public-route-table"
  }
}

#Associate public route table with public subnet
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.pub-subnet.id
  route_table_id = aws_route_table.pub-route-table.id
}


#create elastic ip
resource "aws_eip" "my-eip" {
  domain   = "vpc"
}

#Create Nat gateway
resource "aws_nat_gateway" "my-nwt" {
  allocation_id = aws_eip.my-eip.id
  subnet_id     = aws_subnet.pub-subnet.id

  tags = {
    Name = "my-nwt"
  }
}


# create private route table
resource "aws_route_table" "pri-route-table" {
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.my-nwt.id
    #subnet_id = aws_subnet.pub-subnet.id
  }

  tags = {
    Name = "private-route-table"
  }
}

# Create public security group
resource "aws_security_group" "pub-sg" {
  name        = "pub-sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.my-vpc.id

  tags = {
    Name = "public-sg"
  }
}

# inbound rule
resource "aws_vpc_security_group_ingress_rule" "allow_tla_ipv4" {
  security_group_id = aws_security_group.pub-sg.id
  cidr_ipv4         = aws_subnet.pub-subnet.cidr_block
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}


resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4-1" {
  security_group_id = aws_security_group.pub-sg.id
  cidr_ipv4         = aws_subnet.pub-subnet.cidr_block
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}


resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4-2" {
  security_group_id = aws_security_group.pub-sg.id
  cidr_ipv4         = aws_subnet.pub-subnet.cidr_block
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}





# private security group

resource "aws_security_group" "priv-sg" {
  name        = "priv-sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.my-vpc.id

  tags = {
    Name = "privlic-sg"
  }
}


resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.priv-sg.id
  cidr_ipv4         = aws_vpc.my-vpc.cidr_block
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}


resource "aws_vpc_security_group_ingress_rule" "allow_ipv4" {
  security_group_id = aws_security_group.priv-sg.id
  cidr_ipv4         = aws_vpc.my-vpc.cidr_block
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22


}

resource "aws_vpc_security_group_ingress_rule" "allow_tl_ipv4" {
  security_group_id = aws_security_group.priv-sg.id
  cidr_ipv4         = aws_vpc.my-vpc.cidr_block
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}




#public instance

resource "aws_instance" "ec2-pub" {
  ami           = "ami-0cd59ecaf368e5ccf" # us-west-2
  instance_type = "t2.micro"
  subnet_id = aws_subnet.pub-subnet.id
  vpc_security_group_ids = [aws_security_group.pub-sg.id]
  key_name = "ubuntu"

  tags = {
    Name = "public-ec2"
  }

}

#private instance
resource "aws_instance" "ec2-pri" {
  ami           = "ami-0cd59ecaf368e5ccf" # us-west-2
  instance_type = "t2.micro"
  subnet_id = aws_subnet.pri-subnet.id
  vpc_security_group_ids = [aws_security_group.priv-sg.id]
  key_name = "ubuntu"

  tags = {
    Name = "private-ec2"
  }

}
