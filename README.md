# 🚀 Enterprise Multi-AZ Architecture: Infraestrutura como Código (IaC) e GitOps na AWS

Este repositório contém o laboratório completo de uma arquitetura de nuvem corporativa, resiliente, escalável e totalmente automatizada na AWS. O projeto foi construído utilizando práticas modernas de **Infraestrutura como Código (IaC)** com Terraform e esteiras de **CI/CD / GitOps** com GitHub Actions.

---

## 🗺️ Visão Geral da Arquitetura

A aplicação foi desenhada seguindo as diretrizes de segurança, alta disponibilidade e eficiência de custo do *AWS Well-Architected Framework*. 


A topologia do sistema está dividida em 4 fases incrementais de engenharia:

### 🐳 Fase 1: Containerização da Aplicação
* **Foco:** Empacotamento imutável.
* **Tecnologias:** Docker, Alpine Linux, Nginx.
* **O que foi feito:** Isolamento de uma aplicação web personalizada dentro de uma imagem Docker leve e otimizada (utilizando Alpine como base), garantindo que o sistema rode da mesma forma em qualquer ambiente do planeta.

### 🏗️ Fase 2: Fundação de Rede Resiliente (Multi-AZ)
* **Foco:** Isolamento perimetral e tolerância a falhas físicas.
* **Tecnologias:** AWS VPC, Subnets, Internet Gateway, Route Tables.
* **O que foi feito:** Criação de uma VPC customizada (`10.0.0.0/16`) rejeitando a rede padrão da AWS. Implementação de duas sub-redes públicas distribuídas estrategicamente em zonas de disponibilidade fisicamente separadas (`us-east-1a` e `us-east-1b`) para neutralizar *downtimes* causados por quedas em datacenters da AWS.

### ⚡ Fase 3: Computação de Alta Disponibilidade e Auto-Cura
* **Foco:** Elasticidade automática sob demanda.
* **Tecnologias:** AWS EC2, Launch Templates, Application Load Balancer (ALB), Auto Scaling Group (ASG).
* **O que foi feito:** Implementação de um cluster elástico de servidores EC2 rodando a imagem Docker criada na Fase 1. O tráfego público é recebido por um Load Balancer inteligente que distribui as requisições entre as zonas. Caso um servidor falhe, o Auto Scaling Group executa a **Auto-Cura (Self-Healing)**, destruindo a máquina danificada e erguendo uma nova em segundos.

### 🚀 Fase 4: Esteira de GitOps e Painel de Controle CI/CD
* **Foco:** Governança de infraestrutura sem intervenção manual.
* **Tecnologias:** GitHub Actions, GitHub Secrets, Bash Scripting.
* **O que foi feito:** Automação completa do ciclo de vida da infraestrutura. Foi criado um painel de controle interativo no GitHub Actions utilizando `workflow_dispatch` que permite planejar (`plan`), aplicar (`apply`) ou destruir (`destroy`) qualquer camada do projeto de forma 100% isolada e segura.

---

## 🧠 Decisões de Engenharia de Nível Pleno/Sênior

* **Gerenciamento de Estado Remoto Seguro:** O estado do Terraform (`terraform.tfstate`) não fica exposto localmente. Ele é armazenado em um Bucket S3 remoto e criptografado com versionamento ativo, permitindo auditorias e colaboração segura entre times.
* **Consumo de Estado Desacoplado (`terraform_remote_state`):** A camada de computação (Fase 3) não possui IDs fixos no código (*hardcoded*). Ela consome dinamicamente em tempo real os IDs de rede gerados pela Fase 2 direto do S3, criando um desacoplamento completo de ciclo de vida.
* **Segurança Estrita de Perímetro (Firewall em Camadas):** Os servidores EC2 estão blindados contra ataques diretos da internet. O Security Group das máquinas foi configurado com regras estritas que **só aceitam tráfego vindo do Security Group do Load Balancer**.

---

## 📂 Estrutura do Repositório

```text
projeto-infra-escalavel-aws/
├── .github/workflows/
│   └── terraform.yml       # Código da Pipeline de GitOps (Painel de Controle)
├── fase-1-app-docker/      # Código fonte e Dockerfile da aplicação web
├── fase-2-infra-rede/       # Código Terraform da base de rede customizada
├── fase-3-cluster-ha/      # Código Terraform do cluster elástico e balanceador
└── README.md               # Este guia mestre de arquitetura
```

---

## 👥 Como Replicar este Laboratório na sua Conta AWS

Este projeto foi desenhado para ser **100% portátil**. Qualquer pessoa pode clonar este repositório e erguer essa mesma arquitetura na sua própria conta seguindo estes passos:

### 1. Pré-requisitos
* Ter uma conta ativa na AWS.
* Criar um Bucket S3 na sua conta AWS para armazenar o State do Terraform e atualizar o nome do parâmetro `bucket` nos arquivos `backend.tf` e `cluster.tf`.

### 2. Configurar as Credenciais no GitHub
No seu repositório do GitHub, vá em **Settings** -> **Secrets and variables** -> **Actions** -> **New repository secret** e cadastre as seguintes chaves da sua conta AWS:
* `AWS_ACCESS_KEY_ID`: Seu ID de chave de acesso da AWS.
* `AWS_SECRET_ACCESS_KEY`: Sua chave de acesso secreta da AWS.

### 3. Executar via Painel de Controle
1. Vá até a aba **Actions** no seu GitHub.
2. Selecione a pipeline **🚀 Terraform GitOps Panel**.
3. Clique em **Run workflow**, selecione a fase desejada (`fase-2-infra-rede` primeiro, depois `fase-3-cluster-ha`) e a ação desejada (`apply` para criar, `destroy` para limpar tudo e evitar custos).
```