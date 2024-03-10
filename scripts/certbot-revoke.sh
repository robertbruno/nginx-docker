#!/bin/sh

PRODUCT_NAME=${PRODUCT_NAME:-"nginx-web"}
BASE_PATH=${BASE_PATH:-"$HOME/docker/volumes"}
REASON=${REASON:-"cessationOfOperation"}

docker run --rm  \
  -v ${BASE_PATH}/${PRODUCT_NAME}/letsencrypt/:/etc/letsencrypt \
  certbot/certbot revoke -n \
  --cert-path /etc/letsencrypt/live/${DOMAIN}/cert.pem \
  --reason ${REASON}
