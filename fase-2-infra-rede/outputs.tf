output "vpc_id" {
  value       = aws_vpc.main.id
  description = "O ID da VPC customizada e isolada criada no projeto"
}

output "subnets_publicas_ids" {
  value       = aws_subnet.public[*].id
  description = "Lista contendo os IDs das sub-redes publicas distribuidas"
}