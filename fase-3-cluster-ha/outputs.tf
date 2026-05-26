output "load_balancer_dns" {
  value       = aws_lb.main.dns_name
  description = "A URL publica do Load Balancer para acessar a aplicacao de qualquer lugar"
}