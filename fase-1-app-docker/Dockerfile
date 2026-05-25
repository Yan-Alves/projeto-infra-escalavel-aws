# Imagem base - Nginx Alpine (super leve e segura para produção)
FROM nginx:alpine

# Limpa qualquer arquivo padrão do Nginx que venha na imagem
RUN rm -rf /usr/share/nginx/html/*

# Copia os arquivos locais da pasta atual para o diretório web do Nginx
COPY . /usr/share/nginx/html/

# Documenta que o container trabalha na porta 80
EXPOSE 80

# Inicia o Nginx em primeiro plano para o container não desligar
CMD ["nginx", "-g", "daemon off;"]