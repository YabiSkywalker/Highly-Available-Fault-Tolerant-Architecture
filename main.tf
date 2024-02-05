//establishing a vpc called "prod-vpc"
resource "aws_vpc" "az1-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = "true" #gives you an internal domain name
  enable_dns_hostnames = "true" #gives you an internal host name
  #enable_classiclink = "false"
  instance_tenancy = "default"

  tags = {
    Name = "${var.common_tags}-vpc"
  }
}
//you need an internet gateway established in order to have a portal to the internet 
resource "aws_internet_gateway" "main-igw" {
  vpc_id = aws_vpc.az1-vpc.id

  tags = {
    Name = "prod-igw"
  }
}
//public subnet exclusively to house the NAT gateway, which will point to the internet gateway defined above
resource "aws_subnet" "public-subnet-public-1" {
  vpc_id                  = aws_vpc.az1-vpc.id
  cidr_block              = "10.0.5.0/24"
  map_public_ip_on_launch = "true" //this is what makes it a "public" subnet
  availability_zone       = var.aws_availability_zone-2a

  tags = {
    Name = "public-subnet-1"
  }
}
//public subnet in us-east-2b for NAT gateway in the other az 
resource "aws_subnet" "public-subnet-public-2" {
  vpc_id                  = aws_vpc.az1-vpc.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = "true" //this is what makes it a "public" subnet
  availability_zone       = var.aws_availability_zone-2b

  tags = {
    Name = "public-subnet-2"
  }
}
//this is for the private subnets.  for the ec2 
resource "aws_subnet" "pivate-subnets-1" {
  vpc_id                  = aws_vpc.az1-vpc.id
  cidr_block              = "10.0.10.0/24"
  map_public_ip_on_launch = "false" //this is what makes it a "private" subnet
  availability_zone       = var.aws_availability_zone-2a

  tags = {
    Name = "private-subnet-1"
  }
}
//private subnet for ec2 in us-east-2b
resource "aws_subnet" "pivate-subnets-2" {
  vpc_id                  = aws_vpc.az1-vpc.id
  cidr_block              = "10.0.0.0/24"
  map_public_ip_on_launch = "false" //this is what makes it a "private" subnet
  availability_zone       = var.aws_availability_zone-2b
  tags = {
    Name = "private-subnet-2"
  }
}
//create a route table for the public subnet resource. This will connect the VPC to the internet 
resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.az1-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main-igw.id
  }
  tags = {
    Name = "public-route-table-1"
  }
}
//Route table pointing from the internet to the NAT gateway within the first public subnet
resource "aws_route_table" "public-route-table-1" {
  vpc_id = aws_vpc.az1-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-public-1.id
  }
  tags = {
    Name = "private-route-table-01"
  }
}
//Route table pointing from the internet to the NAT gateway within the  second subnet
resource "aws_route_table" "public-route-table-2" {
  vpc_id = aws_vpc.az1-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat-public-2.id
  }
  tags = {
    Name = "public-route-table-2"
  }
}
//route table association with public subnet
//I am associating the PUBLIC subnets with the PUBLIC route table
//There will be public-subnet-1, and public subnet-2 ONLY to house the NAT gateways.
resource "aws_route_table_association" "public-subnet-association-1" {
  subnet_id      = aws_subnet.public-subnet-public-1.id
  route_table_id = aws_route_table.public-route-table.id
}
//route table association for public subnet housed in us-east-2b
resource "aws_route_table_association" "public-subnet-association-2" {
  subnet_id      = aws_subnet.public-subnet-public-2.id
  route_table_id = aws_route_table.public-route-table.id
}

//private subnet for the db instnace 
resource "aws_subnet" "private-subnet-main" {
  vpc_id                  = aws_vpc.az1-vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = var.aws_availability_zone-2a
  map_public_ip_on_launch = "false"
  tags = {
    name = "private-subnet-main"
  }
}
//private subnet for our db read replica 
resource "aws_subnet" "private-subnet-replica" {
  vpc_id                  = aws_vpc.az1-vpc.id
  cidr_block              = "10.0.4.0/24"
  availability_zone       = var.aws_availability_zone-2b
  map_public_ip_on_launch = "false"
  tags = {
    name = "private-subnet-replica"
  }
}

// Elastic IP address for the internet gateways 
resource "aws_eip" "NAT1" {
  depends_on = [aws_internet_gateway.main-igw]

  tags = {
    name = "eip-nat-1"
  }
}
resource "aws_eip" "NAT2" {
  depends_on = [aws_internet_gateway.main-igw]

  tags = {
    name = "eip-nat-2"
  }
}

//Now creating the NAT gateways themselves 
resource "aws_nat_gateway" "nat-public-1" {
  allocation_id = aws_eip.NAT1.id
  subnet_id     = aws_subnet.public-subnet-public-1.id
  tags = {
    name = "nat-1"
  }
}
resource "aws_nat_gateway" "nat-public-2" {
  allocation_id = aws_eip.NAT2.id
  subnet_id     = aws_subnet.public-subnet-public-2.id
  tags = {
    name = "nat-2"
  }
}
#these are new changes