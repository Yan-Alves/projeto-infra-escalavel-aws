FROM nginx:alpine

# Limpa os arquivos padrão do Nginx antes de colar o nosso site
RUN rm -rf /usr/share/nginx/html/*

COPY . /usr/share/nginx/html/

EXPOSE 80

# Trava o Nginx rodando em primeiro plano pro container não desligar sozinho
CMD ["nginx", "-g", "daemon off;"]