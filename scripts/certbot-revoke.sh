#!/bin/sh

set -e

# Si la variable DEBUG existe, se mostraran las órdenes y sus argumentos mientras se ejecutan.
[ -n "${DEBUG:-}" ] && set -x

REASON=${reason:-"superseded"}
DOMAIN=${domain:-}

certbot revoke -n \
  --verbose \
  --non-interactive \
  --cert-path /etc/letsencrypt/live/${DOMAIN}/cert.pem \
  --reason ${REASON}
