# 🏗️ Lab DevOps - Fase 2: Arquitetura de Rede Resiliente e Multi-AZ com Terraform

Esta pasta contém os arquivos de configuração do Terraform responsáveis por provisionar a base de rede (VPC e Sub-redes) da nossa aplicação na AWS. Toda a infraestrutura foi desenhada seguindo as melhores práticas do *AWS Well-Architected Framework*, com foco em segurança, isolamento e alta disponibilidade.

---

## 🎯 Objetivo e Contexto Técnico

A fundação de qualquer arquitetura de nuvem segura começa pelo design da rede. O objetivo desta fase foi construir uma topologia de rede isolada que elimine o acoplamento de recursos e garanta resiliência contra falhas físicas de datacenters.

Utilizando o **Terraform**, transformamos requisitos de infraestrutura em código declarativo, versionável e idempotente. Isso significa que podemos destruir e reconstruir toda essa rede em minutos, mantendo exatamente o mesmo comportamento e endereçamento de IPs.

---

## 🧠 Defesas Arquiteturais: Por que fizemos essas escolhas?

Ambientes de produção reais exigem justificativas técnicas profundas. Abaixo estão listadas as decisões de engenharia implementadas neste bloco e o que elas demonstram para um recrutador:

### 1. VPC Customizada vs. VPC Padrão (Default)
* **O que foi feito:** Criamos uma VPC totalmente do zero com o bloco CIDR `10.0.0.0/16`.
* **Justificativa de Mercado:** A VPC padrão da AWS vem configurada com sub-redes públicas expostas e uma tabela de rotas genérica. Criar uma VPC customizada garante controle total sobre quem entra e quem sai da rede, permitindo segmentar o tráfego de forma granular e restringir acessos maliciosos a nível de rede.

### 2. Alta Disponibilidade Real (Multi-AZ)
* **O que foi feito:** Provisionamos duas sub-redes públicas distribuídas estrategicamente em Zonas de Disponibilidade distintas (`us-east-1a` e `us-east-1b`).
* **Justificativa de Mercado:** Datacenters físicos estão sujeitos a desastres naturais, quedas de energia ou falhas de hardware. Distribuir nossas sub-redes em zonas logicamente e fisicamente separadas garante que, se a zona `us-east-1a` sofrer uma interrupção total, o tráfego da aplicação será automaticamente absorvido pelos recursos localizados na zona `us-east-1b`, zerando o *downtime* do negócio.

### 3. Gerenciamento de Estado Remoto Seguro (S3 Backend com Versionamento)
* **O que foi feito:** Configuramos o arquivo `backend.tf` para armazenar o estado do Terraform (`terraform.tfstate`) em um Bucket S3 isolado e versionado.
* **Justificativa de Mercado:** O arquivo de estado armazena o mapeamento exato da nossa infraestrutura real. Salvá-lo localmente impossibilita o trabalho em equipe e gera risco de perda de dados. O uso do S3 centraliza o estado para futuras automações de CI/CD, e o **versionamento ativo** do bucket atua como um sistema de *backup* automático caso o arquivo seja corrompido durante uma alteração.

### 4. Modularização e Escalabilidade Dinâmica (`count`)
* **O que foi feito:** Utilizamos a função `count` no recurso de sub-redes para calcular e instanciar os recursos dinamicamente com base no tamanho das listas de CIDR.
* **Justificativa de Mercado:** Evitamos a duplicação de blocos de código (princípio DRY - *Don't Repeat Yourself*). Se no futuro precisarmos expandir a rede para 3 ou 4 zonas de disponibilidade, basta adicionar mais um item na variável da lista no arquivo `variables.tf`, sem a necessidade de reescrever novos blocos de recursos manuais.

---

## 📁 Estrutura de Arquivos desta Fase

```text
fase-2-infra-rede/
├── backend.tf       # Configuração do armazenamento do estado no S3
├── provider.tf      # Definição dos plugins (AWS) e versões requeridas
├── variables.tf     # Declaração das variáveis e blocos CIDR genéricos
├── terraform.tfvars # Valores locais das variáveis (ignorado pelo Git)
├── network.tf       # Definição física da VPC, Subnets, IGW e Rotas
├── outputs.tf       # Exposição dos IDs gerados para reuso nas próximas fases
└── README.md        # Este manual técnico de engenharia de rede
```

---

## 🚀 Como Executar e Validar este Bloco

### 1. Pré-requisitos
* Terraform CLI instalado (`>= 1.0.0`).
* AWS CLI configurado com credenciais válidas que possuam permissão para criar recursos de VPC.
* O Bucket S3 de Remote State previamente criado no console da AWS com o mesmo nome configurado em `backend.tf`.

### 2. Inicialização do Diretório
Baixe os providers necessários e estabeleça a conexão com o backend remoto rodando:
```bash
terraform init
```

### 3. Planejamento (Plan)
Gere o plano de execução para validar se a sintaxe e os recursos estão corretos antes de gastar recursos na nuvem:
```bash
terraform plan
```
*Verifique se o resumo final indica exatamente a intenção de adicionar 7 recursos.*

### 4. Aplicação (Apply)
Envie os comandos para a API da AWS e confirme digitando `yes` quando solicitado:
```bash
terraform apply
```

Ao finalizar, o Terraform exibirá os `Outputs` na tela. Guarde esses valores, pois o ID da VPC e das sub-redes serão injetados diretamente na configuração do nosso Load Balancer e Auto Scaling Group na próxima fase.

---

## 🧹 Limpeza de Recursos (Evitando Custos)

Caso queira remover toda a rede da sua conta AWS para evitar qualquer acúmulo de cobranças indesejadas, execute o comando de destruição:

```bash
terraform destroy
```
*Digite `yes` para confirmar a remoção completa dos 7 recursos criados.*
```