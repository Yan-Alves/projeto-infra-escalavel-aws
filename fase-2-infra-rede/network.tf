resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true 
  enable_dns_support   = true

  tags = {
    Name = "${var.projeto_nome}-vpc"
  }
}

resource "aws_subnet" "public" {
  count                   = length(var.subnets_publicas_cidr)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnets_publicas_cidr[count.index]
  availability_zone       = var.zonas_disponibilidade[count.index]
  map_public_ip_on_launch = true # Garante IP público para os recursos dessa sub-rede

  tags = {
    Name = "${var.projeto_nome}-public-subnet-${count.index + 1}"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.projeto_nome}-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "${var.projeto_nome}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}