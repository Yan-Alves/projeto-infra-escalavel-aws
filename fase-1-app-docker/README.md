# 🐳 Lab DevOps - Fase 1: Engenharia de Aplicação e Containerização Otimizada

Seja bem-vindo à primeira etapa do **Projeto Infraestrutura Escalável: Alta Disponibilidade na AWS**. Esta pasta armazena o componente de *frontend* da nossa solução e encapsula toda a lógica de empacotamento em containers estruturados para ambiente de produção.

Este documento foi desenhado tanto para guiar outros engenheiros na execução local do projeto quanto para documentar as decisões arquiteturais de engenharia que tomamos para garantir performance, segurança e portabilidade.

---

## 🎯 Objetivo e Contexto Técnico

No ciclo de vida tradicional de desenvolvimento, a falta de padronização de ambientes gera gargalos críticos conhecidos como "Configuration Drift" (inconsistências entre a máquina do desenvolvedor e o servidor de produção). 

O objetivo desta fase é neutralizar essa dor através do **isolamento completo de processos**. Ao empacotar nosso servidor web e ativos estáticos dentro de uma imagem Docker imutável, garantimos previsibilidade absoluta: a aplicação se comportará exatamente da mesma forma no seu computador local, na esteira de CI/CD ou distribuída em centenas de instâncias EC2 sob um Load Balancer na AWS.

---

## 🧠 Defesas Arquiteturais: Por que fizemos essas escolhas?

Para um recrutador técnico, o código só faz sentido se houver justificativa de negócio e engenharia por trás. Abaixo estão listadas as boas práticas de nível Pleno/Sênior implementadas neste bloco:

### 1. Seleção da Imagem Base (`nginx:alpine`)
* **O que foi feito:** Escolhemos a distribuição Alpine em detrimento da imagem Nginx padrão baseada em Debian.
* **Justificativa de Mercado:** Imagens baseadas em Debian possuem centenas de megabytes e pacotes desnecessários (como gerenciadores de pacotes complexos e ferramentas de rede). O Alpine Linux reduz o tamanho final da nossa imagem para **menos de 30MB**. Imagens menores significam:
  * **Menor superfície de ataque:** Menos binários instalados significam menos vulnerabilidades potenciais (CVEs) para serem exploradas.
  * **Redução drástica de Toil e Custos:** Deploys e processos de Auto Scaling tornam-se muito mais rápidos, pois o download (pull) da imagem da nuvem leva frações de segundo.

### 2. Higienização de Camadas de Arquivos (`RUN rm -rf`)
* **O que foi feito:** Incluímos uma instrução explícita de remoção dos arquivos padrões do Nginx antes de copiar nosso código.
* **Justificativa de Mercado:** Imagens baseadas em servidores web trazem páginas de boas-vindas estruturais que revelam as versões exatas do software. Remover esses arquivos mitiga o risco de *Information Disclosure* (exposição de informações que atacantes usam para mapear o servidor).

### 3. Estratégia de Cache e Contexto de Build (`.dockerignore`)
* **O que foi feito:** Isolamos arquivos de desenvolvimento, logs locais e documentações do escopo do Docker.
* **Justificativa de Mercado:** Quando executamos o comando de build, o Docker envia todo o diretório para o *Docker Daemon* (Build Context). Isolar arquivos pesados ou desnecessários evita o inchaço da imagem e garante que o Docker aproveite o mecanismo de **camadas em cache**, acelerando futuras pipelines de CI/CD.

---

## 📋 Pré-requisitos para Execução

Antes de iniciar os passos de implantação na sua máquina, certifique-se de ter instalado os seguintes componentes:

1. **Docker Engine / Docker Desktop:** Versão 20.10 ou superior.
2. **Terminal Linux / WSL2:** Recomendado para reproduzir fielmente os comandos Bash.

Para certificar-se de que seu ambiente está pronto, execute a validação abaixo:
```bash
docker --version
```

---

## 🚀 Passos para Implantação Local

Siga rigorosamente as etapas abaixo para compilar e inicializar o projeto na sua máquina de desenvolvimento.

### Passo 1: Clonar e Navegar até o Escopo do Projeto
Se você está executando este projeto a partir do repositório remoto, realize o clone e acesse o diretório específico desta fase:
```bash
# Clone o repositório
git clone [https://github.com/Yan-Alves/projeto-infra-escalavel-aws.git](https://github.com/Yan-Alves/projeto-infra-escalavel-aws.git)

# Acesse a pasta raiz
cd projeto-infra-escalavel-aws

# Entre na pasta correspondente à Fase 1
cd fase-1-app-docker
```

### Passo 2: Construção (Build) da Imagem Customizada
Utilizaremos a flag `-t` para aplicar uma tag organizacional, facilitando o versionamento do artefato:
```bash
docker build -t projeto-infra-local:v1.0 .
```
> 💡 **Nota de Engenharia:** O caractere `.` no final do comando indica o contexto atual. O Docker buscará o arquivo nomeado exatamente como `Dockerfile` nesta pasta para iniciar a compilação das camadas.

### Passo 3: Inicialização do Container em Modo Isolado
Agora, vamos dar o play na aplicação traduzindo a porta interna do servidor para o seu navegador:
```bash
docker run -d -p 8080:80 --name container-projeto-escalavel projeto-infra-local:v1.0
```

**Entendendo os parâmetros críticos utilizados:**
* `-d` (*Detached Mode*): Executa o container em segundo plano, liberando o seu terminal para continuar operando.
* `-p 8080:80` (*Port Forwarding*): Mapeia a porta `8080` da sua máquina física (Host) para a porta `80` interna do container onde o Nginx está escutando.
* `--name`: Atribui um nome amigável ao processo, evitando strings aleatórias e facilitando o gerenciamento via CLI.

### Passo 4: Verificação e Teste de Carga Inicial
Abra o seu navegador web local e acesse o endereço abaixo para checar o funcionamento da interface e dos scripts de monitoramento integrados:
```text
http://localhost:8080
```

Para inspecionar se o Nginx está gerando os logs de acesso corretamente, você pode ler a saída padrão do container em tempo real:
```bash
docker logs -f container-projeto-escalavel
```

---

## 🛠️ Troubleshooting (Resolução de Problemas Comuns)

Caso encontre dificuldades durante a inicialização, verifique os cenários abaixo:

* **Erro: `Port 8080 is already in use`**
  * *Causa:* Outro serviço no seu computador (como um projeto antigo ou outra instância do Nginx) já capturou a porta 8080.
  * *Solução:* Pare o serviço conflitante ou mude o mapeamento do comando para outra porta disponível (ex: `-p 9090:80`).
* **Erro: `Permission denied` ao rodar comandos Docker**
  * *Causa:* Seu usuário local do Linux não possui privilégios administrativos no grupo do Docker.
  * *Solução:* Execute o comando utilizando `sudo` na frente ou adicione permanentemente seu usuário ao grupo do sistema: `sudo usermod -aG docker $USER`.

---

## 🧹 Limpeza de Recursos Locais

Mantendo a boa cultura de SRE (*Site Reliability Engineering*), limpe os resíduos de processos e alocação de memória do seu computador após validar o laboratório:

```bash
# Interrompe a execução do processo do container
docker stop container-projeto-escalavel

# Remove o container do escopo do Docker Engine
docker rm container-projeto-escalavel
```