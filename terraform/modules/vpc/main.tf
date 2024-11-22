# Create vpc with specific cider block 
resource "aws_vpc" "aws_vpc" {
  cidr_block = var.vpc_cidr_block
  tags = {
    Name = var.vpc_Name,
    created-by="john"
  }
}

# Create public subnets with specific cider block 
resource "aws_subnet" "public_subnet" {
  count =length(var.public_subnets_cidr)
  vpc_id = aws_vpc.aws_vpc.id
  cidr_block =var.public_subnets_cidr[count.index]
  availability_zone = var.availability_Zones_subnet[count.index]
 tags = {
    Name = "public-subnet-${count.index + 1}-${var.vpc_Name}"
    created-by="john"
  }

}


# Create an internet gateway
resource "aws_internet_gateway" "internet_gateway" {
  count = length(var.public_subnets_cidr) > 0 ? 1 : 0  
  vpc_id =  aws_vpc.aws_vpc.id

  tags = {
    Name = "igw-${var.vpc_Name}"
    created-by="john"
  }

}

# Create a route table for public subnets
resource "aws_route_table" "public_route_table" {
  count = length(var.public_subnets_cidr) > 0 ? 1 : 0  #use to prevent creation of rw if not public subnet entered 
  vpc_id =  aws_vpc.aws_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway[0].id
  }

  tags = {
    Name = "route_table_${var.vpc_Name}"
    created-by="john"
  }
}



# Associate public subnets with the public route table
resource "aws_route_table_association" "public_association" {
  count          = length(var.public_subnets_cidr)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table[0].id
  
}
