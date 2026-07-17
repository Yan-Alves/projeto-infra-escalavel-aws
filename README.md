# Projeto Infraestrutura Escalável AWS

Eu montei esse projeto para trabalhar com um funcionamento real de uma estrutura rodando na nuvem da AWS. Usei o Terraform para escrever toda a infraestrutura por código e o GitHub Actions para gerenciar o fluxo de automação. A minha ideia aqui foi colocar um site estático bem simples para rodar dentro de um container Docker, mas de um jeito seguro e profissional. O tráfego de quem acessa é distribuído de forma automática e se algum servidor físico der problema lá na AWS, a própria estrutura percebe, se vira sozinha para corrigir e o site continua no ar, sem eu precisar intervir nesse processo.

---

### Meus Objetivos com o Projeto
* **Disponibilidade Real:** Eu configurei o ambiente para que o site continue online mesmo se um datacenter inteiro da AWS sofra uma pane física.
* **Segurança de Perímetro:** As instâncias EC2 não aceitam conexões diretas da internet. O tráfego passa obrigatoriamente pela triagem do Load Balancer.
* **Automação:** Eu tirei a necessidade de rodar comandos manualmente no terminal da minha própria máquina. Tudo é gerenciado direto pela aba Actions do GitHub.

### Ferramentas que usei
* **Docker:** Usei para empacotar a aplicação web de um jeito leve, isolado e imutável.
* **Terraform:** Usei para escrever e orquestrar os recursos da AWS como código
* **AWS (VPC, Subnets, EC2, ALB, ASG):** O provedor de nuvem que escolhi para hospedar a rede e os servidores.
* **S3 Bucket:** Criei um bucket e guardei o arquivo de histórico (`terraform.tfstate`) com tudo o que o Terraform criou na AWS.
* **GitHub Actions:** Utilizei workflows automatizados para provisionar e gerenciar a infraestrutura diretamente pela interface web do GitHub, eliminando a necessidade de executar comandos manualmente.

---

## Requisitos

Para rodar esse projeto, você vai precisar de:
* Uma conta ativa na **AWS** com permissões de administrador.
* Um repositório próprio no **GitHub** para hospedar o código.
* As chaves de acesso da CLI da AWS (`Access Key ID` e `Secret Access Key`) configuradas nos segredos do repositório.

---

## Arquivos do Projeto

Eu separei as configurações em pastas e arquivos específicos para que o ciclo de vida da rede não fique preso ao ciclo de vida dos servidores:

* **`.github/workflows/terraform.yml`**: Onde configurei os comandos automáticos e os botões do painel do GitHub.
* **`fase-1-app-docker/Dockerfile`**: O arquivo que usei para estruturar a imagem Docker leve do nosso site.
* **`fase-2-infra-rede/network.tf`**: Onde escrevi toda a fundação de rede (VPC, sub-redes, rotas e gateway).
* **`fase-2-infra-rede/backend.tf`**: Configuração que avisa ao Terraform para salvar o estado da rede lá no S3.
* **`fase-3-cluster-ha/cluster.tf`**: Onde configurei o Load Balancer, o Auto Scaling e as regras estritas de firewall.
* **`fase-3-cluster-ha/backend.tf`**: Arquivo que conecta essa fase à rede anterior e salva o estado do cluster no S3.

---

## Estrutura e Arquitetura do Projeto

Abaixo mostro como organizei as pastas do projeto no VS Code e o fluxo lógico das dependências:

```text
projeto-infra-escalavel-aws/
├── .github/workflows/
│   └── terraform.yml       # Fase 4: Automação
├── fase-1-app-docker/      # Fase 1: Dockerfile e Código da aplicação
├── fase-2-infra-rede/       # Fase 2: Malha de Rede e Estado Remoto
└── fase-3-cluster-ha/      # Fase 3: Cluster de Computação e Balanceamento
```


---

## Passos para Implantação

A implantação foi desenhada para ser executada sem você precisar digitar comandos no terminal local. Eu parametrizuei tudo para rodar direto pelo GitHub Actions:

### 1. Clonando o Repositório
```bash
git clone [https://github.com/Yan-Alves/projeto-infra-escalavel-aws.git](https://github.com/Yan-Alves/projeto-infra-escalavel-aws.git)
cd projeto-infra-escalavel-aws
```

### 2. Configurando o Cofre de Segredos (GitHub Secrets)
No menu do meu repositório no GitHub, acessei **Settings** -> **Secrets and variables** -> **Actions** -> **New repository secret** e cadastrei as chaves da AWS com esses nomes exatos:
* `AWS_ACCESS_KEY_ID`
* `AWS_SECRET_ACCESS_KEY`

### 3. Subindo a Camada de Rede (Fase 2)
1. Fui até a aba **Actions** no topo do meu repositório no GitHub.
2. No menu lateral esquerdo, cliquei em ** Terraform GitOps **.
3. Cliquei no botão **Run workflow** no lado direito da tela.
4. No campo da fase, selecionei `fase-2-infra-rede` e na ação escolhi `apply`.
5. Cliquei no botão verde. O processo rodou automático, criou a VPC, as sub-redes e guardou o estado no S3 de forma limpa.

### 4. Subindo o Cluster de Servidores (Fase 3)
1. Na mesma página do painel Actions, cliquei de novo em **Run workflow**.
2. Dessa vez, mudei o seletor da fase para `fase-3-cluster-ha` e mantive a ação em `apply`.
3. Mandei rodar. O Terraform consultou o estado da rede criada no passo anterior e provisionou o cluster elástico completo na nuvem da AWS.

### 5. Testando o site no Navegador
Quando a Fase 3 terminou com sucesso, entrei nos logs do passo `Terraform Action`, peguei a URL gerada no output (`load_balancer_dns`) e colei no meu navegador. O site carregou na hora!

---

## Arquivos de Configuração

Aqui separei os trechos de código mais importantes que eu escrevi para estruturar os pontos críticos do ecossistema do projeto:

### `Dockerfile`
```dockerfile
FROM nginx:alpine

# Limpa os arquivos padrão do Nginx antes de colar o nosso site
RUN rm -rf /usr/share/nginx/html/*

COPY . /usr/share/nginx/html/

EXPOSE 80

# Trava o Nginx rodando em primeiro plano pro container não desligar sozinho
CMD ["nginx", "-g", "daemon off;"]
```

### `network.tf`
```hcl
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
  map_public_ip_on_launch = true # Garante um IP público para os recursos dessa sub-rede

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
```

### `cluster.tf`
```hcl
# Puxa os dados da VPC e das sub-redes criadas na Fase 2 direto do S3
data "terraform_remote_state" "rede" {
  backend = "s3"
  config = {
    bucket = "<COLOQUE_AQUI_O_NOME_DO_SEU_BUCKET>"
    key    = "fase-2/terraform.tfstate"
    region = "us-east-1"
  }
}

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

# As EC2 passam a ignorar a internet e só respondem ao Security Group do ALB
resource "aws_security_group" "ec2" {
  name        = "${var.projeto_nome}-ec2-sg"
  description = "Permite trafego HTTP vindo estritamente do Security Group do ALB"
  vpc_id      = data.terraform_remote_state.rede.outputs.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
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

resource "aws_launch_template" "app" {
  name_prefix   = "${var.projeto_nome}-template-"
  image_id      = "ami-0c7217cdde317cfec" 
  instance_type = var.instancia_tipo

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.ec2.id]
  }

  # Script para ligar as EC2 já com Docker instalado e o container rodando
  user_data = base64encode(<<-EOF
              #!/bin/bash
              sudo dnf update -y
              sudo dnf install -y docker git
              sudo systemctl start docker
              sudo systemctl enable docker
              
              cd /home/ec2-user
              git clone [https://github.com/](https://github.com/)<SEU_USUARIO_DO_GITHUB>/projeto-infra-escalavel-aws.git
              cd projeto-infra-escalavel-aws/fase-1-app-docker
              
              docker build -t app-projeto:v1.0 .
              docker run -d -p 80:80 --name webapp app-projeto:v1.0
              EOF
  )

  lifecycle {
    create_before_destroy = true
  }
}

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

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

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
```

### `terraform.yml`
```yaml
name: "Terraform GitOps"

on:
  # Ativa o painel de botões manuais na aba Actions do GitHub
  workflow_dispatch:
    inputs:
      fase:
        description: 'Selecione a fase da infraestrutura'
        required: true
        type: choice
        options:
          - 'fase-2-infra-rede'
          - 'fase-3-cluster-ha'
      acao:
        description: 'Selecione a acao do Terraform'
        required: true
        type: choice
        options:
          - 'plan'
          - 'apply'
          - 'destroy'

  pull_request:
    branches:
      - main
    paths:
      - 'fase-2-infra-rede/**'
      - 'fase-3-cluster-ha/**'

jobs:
  terraform:
    name: "Terraform Execution"
    runs-on: ubuntu-latest

    env:
      AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
      AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
      AWS_DEFAULT_REGION: "us-east-1"

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      # Instala o Terraform na máquina temporária do GitHub
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "1.5.7"

      # Decide qual pasta e ação executar
      - name: Set Target Directory
        id: set-dir
        run: |
          if [ "${{ github.event_name }}" = "workflow_dispatch" ]; then
            echo "dir=${{ github.event.inputs.fase }}" >> $GITHUB_OUTPUT
            echo "action=${{ github.event.inputs.acao }}" >> $GITHUB_OUTPUT
          else
            if git diff --name-only ${{ github.event.before }} ${{ github.event.after }} | grep -q "fase-2-infra-rede"; then
              echo "dir=fase-2-infra-rede" >> $GITHUB_OUTPUT
            else
              echo "dir=fase-3-cluster-ha" >> $GITHUB_OUTPUT
            fi
            echo "action=plan" >> $GITHUB_OUTPUT
          fi

      # Inicializa o Terraform na pasta selecionada
      - name: Terraform Init
        run: |
          cd ${{ steps.set-dir.outputs.dir }}
          terraform init

      - name: Terraform Action
        run: |
          cd ${{ steps.set-dir.outputs.dir }}
          
          if [ "${{ steps.set-dir.outputs.action }}" = "plan" ]; then
            terraform plan
          elif [ "${{ steps.set-dir.outputs.action }}" = "apply" ]; then
            terraform apply -auto-approve
          elif [ "${{ steps.set-dir.outputs.action }}" = "destroy" ]; then
            terraform destroy -auto-approve
          fi
```

---

## Os pontos-chave da arquitetura do projeto

### 1. Isolamento entre rede e servidores
Em vez de jogar tudo em um arquivo gigante, procurei dividir a infraestrutura em fases. Assim, conseguirei mexer nas máquinas ou atualizar o site sem o risco de afetar a estabilidade da rede sem querer.

### 2. Histórico do Terraform no S3 de forma segura
Configurei o Terraform para banir o salvamento local do arquivo de estado. Criei um bucket S3 com criptografia e histórico de versões ativado para guardar o `terraform.tfstate` com total segurança.

### 3. Conectando as fases sem dados estáticos
Usei o bloco `terraform_remote_state` para que o cluster descubra os IDs da rede direto no S3 em tempo real, eliminando dados estáticos do código.

### 4. Bloqueio de acesso direto da internet
Blindei os servidores, e assim as instâncias EC2 ignoram qualquer requisição direta vinda da internet aberta. Configurei uma regra cruzada estabelecendo que elas só aceitam pacotes vindos estritamente do Security Group do Load Balancer.

### 5. Resiliência e troca automática de servidores fora do ar
O Auto Scaling Group trabalha junto com o Load Balancer distribuindo as instâncias de forma paralela por zonas de disponibilidade fisicamente distantes (`us-east-1a` e `us-east-1b`). Se um servidor falhar, o sistema desliga a máquina com defeito e cria outra nova no lugar na mesma hora.

### 6. Controle total via painel no GitHub
Removi a necessidade de abrir o terminal local do meu computador ou rodar comandos na minha máquina para gerenciar a infraestrutura. Integrei o ciclo completo do Terraform ao GitHub Actions usando `workflow_dispatch`, transformando a gestão da infraestrutura em cliques rápidos protegidos por chaves criptografadas.

---

##  Conclusão

Nesse projeto consegui juntar Docker, Terraform e GitHub Actions em uma única automação, e isso me ajudou a praticar um cenário possível para a atuação de um DevOps. 

Desenvolver esse projeto me ajudou a enxergar que dá para subir e apagar ambientes de um jeito bem seguro e rápido. Ver o Terraform se conectando com a AWS e gerenciando tudo a partir de um clique no painel do GitHub foi sensacional, e me trouxe uma boa experiência sobre automação.