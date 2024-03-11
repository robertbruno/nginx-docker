# Utiliza la imagen base de Nginx
FROM nginx

RUN apt-get update\
      && apt-get install -y \
      certbot python3-certbot-nginx

COPY resources/utils /etc/nginx/utils

COPY nginx.conf /etc/nginx/nginx.conf

COPY resources/templates /etc/nginx/templates

EXPOSE 80 443

# Comando para iniciar Nginx cuando se ejecute el contenedor
CMD ["nginx", "-g", "daemon off;"]
