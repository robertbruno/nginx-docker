# Utiliza la imagen base de Nginx
FROM nginx

# https://certbot.eff.org/
RUN apt-get update\
      && apt-get install -y \
      certbot python3-certbot-nginx

RUN apt install -y wget
RUN echo "deb [signed-by=/usr/share/keyrings/azlux-archive-keyring.gpg] http://packages.azlux.fr/debian/ stable main" | \
      tee /etc/apt/sources.list.d/azlux.list \
      && wget -O /usr/share/keyrings/azlux-archive-keyring.gpg  https://azlux.fr/repo.gpg \
      && apt update && apt install -y webhookd
  
COPY scripts /scripts

# nginx config files
COPY nginx.conf /etc/nginx/nginx.conf
COPY resources/utils /etc/nginx/utils
COPY resources/templates /etc/nginx/templates
COPY /80-webhookd.sh /docker-entrypoint.d/80-webhookd.sh
RUN chmod +x /docker-entrypoint.d/80-webhookd.sh

# clean
RUN apt-get clean \
      && rm -rf /var/lib/apt/lists/*

EXPOSE 80 8080 443

# Comando para iniciar Nginx cuando se ejecute el contenedor
CMD ["nginx", "-g", "daemon off;"]
