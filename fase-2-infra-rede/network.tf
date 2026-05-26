# 1. Criação da VPC Customizada (O isolamento do nosso ambiente)
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true # Permite que os recursos ganhem nomes de domínio internos
  enable_dns_support   = true

  tags = {
    Name = "${var.projeto_nome}-vpc"
  }
}

# 2. Criação das Sub-redes Públicas redundantes (Multi-AZ)
resource "aws_subnet" "public" {
  count                   = length(var.subnets_publicas_cidr)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.subnets_publicas_cidr[count.index]
  availability_zone       = var.zonas_disponibilidade[count.index]
  map_public_ip_on_launch = true # Garante que os recursos nessa rede ganhem IP público (essencial para o Load Balancer)

  tags = {
    Name = "${var.projeto_nome}-public-subnet-${count.index + 1}"
  }
}

# 3. Criação do Internet Gateway (A porta de comunicação com o mundo exterior)
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.projeto_nome}-igw"
  }
}

# 4. Tabela de Roteamento para direcionar o tráfego público para a internet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0" # Representa qualquer endereço IP da internet
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "${var.projeto_nome}-public-rt"
  }
}

# 5. Associação das Sub-redes Públicas com a nossa Tabela de Roteamento
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}