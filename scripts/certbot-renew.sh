#!/bin/sh

PRODUCT_NAME=${PRODUCT_NAME:-"nginx-web"}
BASE_PATH=${BASE_PATH:-"$HOME/docker/volumes"}

docker run --rm  \
    -v ${BASE_PATH}/${PRODUCT_NAME}/letsencrypt:/etc/letsencrypt \
    -v ${BASE_PATH}/${PRODUCT_NAME}/www:/usr/share/nginx/html/ \
    certbot/certbot \
    --no-random-sleep-on-renew \
    --webroot-path /usr/share/nginx/html/ \
    --noninteractive \
    renew