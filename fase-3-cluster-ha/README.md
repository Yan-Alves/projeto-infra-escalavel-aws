# ⚡ Lab DevOps - Fase 3: Computação, Alta Disponibilidade e Frota Elástica com Terraform

Esta pasta armazena as configurações do Terraform responsáveis por provisionar a camada de computação resiliente da nossa aplicação. Aqui, estruturamos um cluster elástico utilizando um **Application Load Balancer (ALB)** e um **Auto Scaling Group (ASG)** para gerenciar nossas instâncias EC2 rodando Docker.

---

## 🎯 Objetivo e Contexto Técnico

Não basta colocar uma aplicação na nuvem; ela precisa ser resiliente a picos de tráfego e imune a quedas de servidores individuais. O objetivo desta fase foi implementar uma arquitetura elástica e tolerante a falhas (*Fault-Tolerant*).

Em vez de apontar o tráfego diretamente para um único servidor, os usuários se conectam a um balanceador de carga inteligente. Este balanceador distribui as requisições entre várias instâncias EC2 distribuídas em diferentes datacenters físicos (Multi-AZ), garantindo estabilidade absoluta e performance escalável.

---

## 🧠 Defesas Arquiteturais: Por que fizemos essas escolhas?

Este bloco demonstra maturidade técnica de nível Pleno/Sênior através de decisões estratégicas de design de infraestrutura:

### 1. Consumo Dinâmico de Estado (`terraform_remote_state`)
* **O que foi feito:** A computação lê os dados de rede diretamente do arquivo de memória da Fase 2 armazenado no S3.
* **Justificativa de Mercado:** Evita a prática de fixar manualmente (*hardcode*) IDs de VPC e Subnets no código. Isso desacopla o ciclo de vida da infraestrutura: a equipe de rede pode alterar a estrutura de sub-redes sem quebrar ou exigir modificações manuais no código da equipe de computação.

### 2. Segurança Estrita de Perímetro (Firewall em Camadas)
* **O que foi feito:** O Security Group das instâncias EC2 possui uma regra de entrada (*Ingress*) estrita que aceita tráfego HTTP **apenas** se a requisição vier do Security Group do Load Balancer.
* **Justificativa de Mercado:** Blindagem de perímetro. Mesmo que as instâncias EC2 possuam IPs públicos, qualquer tentativa de varredura ou ataque direto da internet na porta 80 será sumariamente bloqueada pelo firewall da AWS. O único caminho possível para alcançar a aplicação é passando pelas checagens do Load Balancer.

### 3. Auto-Cura e Elasticidade (ASG + Multi-AZ)
* **O que foi feito:** Configuramos o Auto Scaling Group para manter uma capacidade mínima de 2 instâncias (garantindo Alta Disponibilidade contínua) e máxima de 4.
* **Justificativa de Mercado:** Tolerância a falhas e eficiência de custo. Se um servidor sofrer um travamento de sistema operacional ou o datacenter da AWS apagar, o ASG detecta a falha através das checagens de saúde do *Target Group* e realiza a **auto-cura (Self-Healing)**, destruindo a máquina defeituosa e erguendo uma nova em segundos. Além disso, se o volume de acessos disparar, o cluster escala até 4 máquinas automaticamente, reduzindo a frota quando o pico passa para economizar recursos financeiros.

### 4. Provisionamento Automatizado de Inicialização (*User Data*)
* **O que foi feito:** Injetamos um script Bash codificado em Base64 dentro do *Launch Template* das instâncias.
* **Justificativa de Mercado:** Eliminação do trabalho manual (*Zero Toil*). Sempre que o Auto Scaling precisa criar uma máquina nova, ela executa de forma idêntica e automatizada: atualiza pacotes, instala o Docker e o Git, clona o repositório do projeto e compila/roda o container Docker estruturado na Fase 1.

---

## 📁 Estrutura de Arquivos desta Fase

```text
fase-3-cluster-ha/
├── backend.tf       # Configuração do armazenamento do estado da computação no S3
├── provider.tf      # Definição dos plugins (AWS) requeridos
├── variables.tf     # Declaração das variáveis de tamanho de cluster e tipos de EC2
├── terraform.tfvars # Valores locais de ambiente (ignorado pelo Git)
├── cluster.tf       # O cérebro da alta disponibilidade (ALB, ASG, SG e Templates)
├── outputs.tf       # Exposição da URL pública do Load Balancer
└── README.md        # Este manual técnico de engenharia de computação
```

---

## 🚀 Como Executar e Validar este Bloco

### 1. Inicialização do Diretório
```bash
terraform init
```

### 2. Planejamento (Plan)
```bash
terraform plan
```
*Valide se o Terraform realizou a leitura do Remote State com sucesso e planejou a adição de 7 recursos.*

### 3. Aplicação (Apply)
```bash
terraform apply
```
*Confirme com `yes`. O processo levará cerca de 3 minutos devido à propagação física do Load Balancer nos datacenters da AWS.*

### 4. Validação
Ao final do processo, copie a URL gerada no terminal (Output `load_balancer_dns`) e cole no seu navegador para acessar a aplicação distribuída.

---

## 🧹 Limpeza de Recursos (Evitando Custos)

Para destruir os servidores, o balanceador de carga e interromper qualquer tarifação na sua conta da AWS, execute:

```bash
terraform destroy
```
*Digite `yes` para confirmar a remoção completa dos 7 recursos de computação.*
```