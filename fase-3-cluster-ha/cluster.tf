# 1. Busca automatizada dos dados de rede da Fase 2 salvos no S3
data "terraform_remote_state" "rede" {
  backend = "s3"
  config = {
    bucket = "projeto-infra-escalavel-tfstate-yan-2026"
    key    = "fase-2/terraform.tfstate"
    region = "us-east-1"
  }
}

# 2. Security Group do Load Balancer (ALB) - Permite HTTP vindo de qualquer lugar da internet
resource "aws_security_group" "alb" {
  name        = "${var.projeto_nome}-alb-sg"
  description = "Permite trafego HTTP publico para o Load Balancer"
  vpc_id      = data.terraform_remote_state.rede.outputs.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.projeto_nome}-alb-sg"
  }
}

# 3. Security Group das Instâncias EC2 - REGRAS ESTRITAS: Só aceita requisições que venham do ALB
resource "aws_security_group" "ec2" {
  name        = "${var.projeto_nome}-ec2-sg"
  description = "Permite trafego HTTP vindo estritamente do Security Group do ALB"
  vpc_id      = data.terraform_remote_state.rede.outputs.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id] # Vinculo de seguranca direta
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.projeto_nome}-ec2-sg"
  }
}

# 4. Launch Template - A receita de bolo que define como as nossas EC2 vao nascer
resource "aws_launch_template" "app" {
  name_prefix   = "${var.projeto_nome}-template-"
  image_id      = "ami-0c7217cdde317cfec" # Amazon Linux 2023 LTS padrao da regiao us-east-1
  instance_type = var.instancia_tipo

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ec2.id]
  }

  # Script de automacao (User Data): Instala o Docker, clona seu repositorio e roda o container da Fase 1
  user_data = base64encode(<<-EOF
              #!/bin/bash
              sudo dnf update -y
              sudo dnf install -y docker git
              sudo systemctl start docker
              sudo systemctl enable docker
              
              cd /home/ec2-user
              git clone https://github.com/Yan-Alves/projeto-infra-escalavel-aws.git
              cd projeto-infra-escalavel-aws/fase-1-app-docker
              
              docker build -t app-projeto:v1.0 .
              docker run -d -p 80:80 --name webapp app-projeto:v1.0
              EOF
  )

  lifecycle {
    create_before_destroy = true
  }
}

# 5. Application Load Balancer (ALB) - O distribuidor de trafego Multi-AZ
resource "aws_lb" "main" {
  name               = "${var.projeto_nome}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.terraform_remote_state.rede.outputs.subnets_publicas_ids

  tags = {
    Name = "${var.projeto_nome}-alb"
  }
}

# 6. Target Group - O grupo de destino onde o ALB vai pendurar as EC2 criadas pelo Auto Scaling
resource "aws_lb_target_group" "app" {
  name     = "${var.projeto_nome}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.rede.outputs.vpc_id

  health_check {
    path                = "/"
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

# 7. Listener - Vincula o Load Balancer na porta 80 ao nosso Target Group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# 8. Auto Scaling Group (ASG) - O gerenciador da frota elastica Multi-AZ
resource "aws_autoscaling_group" "app" {
  name_prefix         = "${var.projeto_nome}-asg-"
  desired_capacity    = var.cluster_min_size
  max_size            = var.cluster_max_size
  min_size            = var.cluster_min_size
  target_group_arns   = [aws_lb_target_group.app.arn]
  vpc_zone_identifier = data.terraform_remote_state.rede.outputs.subnets_publicas_ids

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "${var.projeto_nome}-webserver"
    propagate_at_launch = true
  }
}