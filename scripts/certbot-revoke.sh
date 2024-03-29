#!/bin/sh

REASON=${reason:-"superseded"}
DOMAIN=${domain:-}

certbot revoke -n \
  --non-interactive \
  --cert-path /etc/letsencrypt/live/${DOMAIN}/cert.pem \
  --reason ${REASON}
