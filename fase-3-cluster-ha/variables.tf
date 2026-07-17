variable "aws_region" {
  type        = string
  description = "Regiao da AWS"
  default     = "us-east-1"
}

variable "projeto_nome" {
  type        = string
  description = "Nome base do projeto"
  default     = "projeto-infra-escalavel"
}

variable "instancia_tipo" {
  type        = string
  description = "Tipo da instancia EC2 para os servidores web"
  default     = "t2.micro"
}

variable "cluster_min_size" {
  type        = number
  description = "Quantidade minima de servidores ativos"
  default     = 2
}

variable "cluster_max_size" {
  type        = number
  description = "Quantidade maxima de servidores no pico de acessos"
  default     = 4
}