variable "aws_region" {
  type        = string
  description = "Regiao da AWS onde a infraestrutura sera provisionada"
  default     = "us-east-1"
}

variable "projeto_nome" {
  type        = string
  description = "Nome base do projeto para aplicar nas tags dos recursos"
  default     = "projeto-infra-escalavel"
}

variable "vpc_cidr" {
  type        = string
  description = "Bloco de IPs (CIDR) para a VPC customizada"
  default     = "10.0.0.0/16"
}

variable "subnets_publicas_cidr" {
  type        = list(string)
  description = "Lista de blocos de IPs para as subnets publicas (Multi-AZ)"
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "zonas_disponibilidade" {
  type        = list(string)
  description = "Zonas de disponibilidade para garantir a resiliencia Multi-AZ"
  default     = ["us-east-1a", "us-east-1b"]
}