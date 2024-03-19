#!/bin/sh

REASON=${reason:-}
DOMAIN=${domain:-}

certbot revoke -n \
  --non-interactive \
  --cert-path /etc/letsencrypt/live/${DOMAIN}/cert.pem \
  --reason ${REASON}
