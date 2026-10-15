#!/bin/sh
# Entrypoint 05: limpia el template default de nginx en modo Railway.
#
# El template default de AWS (default.conf) tiene `default_server` con
# `server_name localhost` y carga antes que 00-health.conf alfabeticamente.
# Cuando el healthcheck de Railway pega /health sin Host valido, nginx lo
# matchea contra default.conf y devuelve 404, reiniciando el container en
# loop.
#
# En modo Railway los templates-railway ya tienen un default_server propio
# (00-health.conf) que responde 200 en /health. El default.conf de AWS no
# aplica y hay que quitarlo para que no compita.
#
# En AWS NGINX_ENVSUBST_TEMPLATE_DIR no se setea (default /etc/nginx/templates)
# y este script no toca nada.
set -e

TEMPLATE_DIR="${NGINX_ENVSUBST_TEMPLATE_DIR:-/etc/nginx/templates}"

if [ "$TEMPLATE_DIR" = "/etc/nginx/templates-railway" ]; then
    rm -f /etc/nginx/conf.d/default.conf
    echo "05-railway-cleanup.sh: modo Railway, default.conf de AWS eliminado"
else
    echo "05-railway-cleanup.sh: modo AWS, default.conf se conserva"
fi
