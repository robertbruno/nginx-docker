#!/bin/sh

certbot/certbot revoke -n \
  --cert-path /etc/letsencrypt/live/${DOMAIN}/cert.pem \
  --reason ${REASON}
