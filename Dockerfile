# Utiliza la imagen base de Nginx
# Compartida entre AWS (ECS, detras de ALB) y Railway (detras de su edge/TLS).
# El entrypoint oficial de la imagen nginx ya hace envsubst de /etc/nginx/templates/*.template
# -> /etc/nginx/conf.d/*.conf usando variables de entorno (ninguna accion extra requerida).
#
# Tag fijo en vez de :latest: el build debe ser reproducible. 1.31.x es la rama
# mainline (numero menor impar); base Debian trixie, requerida por los apt-get
# de certbot/awscli/webhookd mas abajo.
FROM nginx:1.31.7

# https://certbot.eff.org/
RUN apt-get update\
      && apt-get install -y \
      certbot python3-certbot-nginx \
      cron \
      apache2-utils \
      wget \
      awscli \
      jq \
      curl

RUN echo "deb [signed-by=/usr/share/keyrings/azlux-archive-keyring.gpg] http://packages.azlux.fr/debian/ stable main" | \
      tee /etc/apt/sources.list.d/azlux.list \
      && wget -O /usr/share/keyrings/azlux-archive-keyring.gpg  https://azlux.fr/repo.gpg \
      && apt update && apt install -y webhookd

COPY scripts /scripts
RUN chmod +x /scripts/*.sh

# nginx config files
COPY nginx.conf /etc/nginx/nginx.conf
COPY resources/utils /etc/nginx/utils

# Templates AWS (default) y Railway (en directorio aparte).
# El entrypoint oficial procesa con envsubst el dir apuntado por
# NGINX_ENVSUBST_TEMPLATE_DIR (default /etc/nginx/templates).
# Railway debe setear: NGINX_ENVSUBST_TEMPLATE_DIR=/etc/nginx/templates-railway
COPY resources/templates /etc/nginx/templates
COPY resources/templates-railway /etc/nginx/templates-railway

# Admin panel
COPY resources/admin /var/www/admin

COPY resources/80-webhookd.sh /docker-entrypoint.d/80-webhookd.sh
COPY resources/90-cron.sh /docker-entrypoint.d/90-cron.sh
RUN chmod +x /docker-entrypoint.d/*.sh

COPY resources/crontab /etc/cron.d/crontab
RUN chmod 0644 /etc/cron.d/crontab && \
      crontab /etc/cron.d/crontab

# clean
RUN apt-get clean \
      && rm -rf /var/lib/apt/lists/* \
      && rm -rf /etc/cron.d/certbot

EXPOSE 80 8080 443

ENV NGINX_RESOLVER=127.0.0.1 \
  PORT=80 \
  WHD_HOOK_TIMEOUT=300 \
  WHD_PASSWD_FILE=/etc/webhookd/users.htpasswd \
  WHD_USER=webhookd \
  WHD_PASSWD=

# Comando para iniciar Nginx cuando se ejecute el contenedor
CMD ["nginx", "-g", "daemon off;"]
