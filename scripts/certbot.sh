#!/bin/bash

PRODUCT_NAME=${PRODUCT_NAME:-"nginx-web"}
DEFAULT_MAIL=${DEFAULT_MAIL:-""}
BASE_PATH=${BASE_PATH:-"$HOME/docker/volumes"}
EXPAND=${EXPAND:-}
DOMAIN=${DOMAIN:-}
DOCKER_NAME=${PRODUCT_NAME}_cerbot

usage="
$(basename "$0") [-d domain] [-e expand]

Create o expand a certificated

where:
    -h  show this help text
    -d  domain name to create or expand
    -e  space separate list of domain to add to the primary domain.
    -b  directorio de volumes
    -m  mail to notify
    -p  Product name
"

while getopts ":h:d:e:b:m:p:" opt; do
  case ${opt} in

    h)      
      printf $usage
      exit 1
      ;;  
    d )
      DOMAIN=$OPTARG
      ;;
    e )
      EXPAND=$OPTARG
      ;;
    b )
      BASE_PATH=$OPTARG
      ;;
    m )
      DEFAULT_MAIL=$OPTARG
      ;;
    p )
      PRODUCT_NAME=$OPTARG
      ;;
    \? )
      ;;
    : )
      ;;
  esac
done
shift $((OPTIND -1))

if [ -z "${DOMAIN}" ]; then
    echo "${usage}"
    exit 1
fi

docker rm -f ${DOCKER_NAME} 2>/dev/null;

if [[ -z "$EXPAND" ]]; then
    echo "Sigle domain ${DOMAIN}"
    docker run --rm -it --name ${DOCKER_NAME} \
    -v ${BASE_PATH}/${PRODUCT_NAME}/letsencrypt/:/etc/letsencrypt \
    -v ${BASE_PATH}/${PRODUCT_NAME}/www/:/usr/share/nginx/html/ \
    certbot/certbot \
    certonly \
    --agree-tos \
    --webroot \
    --webroot-path=/usr/share/nginx/html/ \
    --email ${DEFAULT_MAIL} \
    --keep \
    -d ${DOMAIN}
else
    echo "Expand domain ${DOMAIN}"
    docker run --rm -it --name ${DOCKER_NAME} \
    -v ${BASE_PATH}/${PRODUCT_NAME}/letsencrypt/:/etc/letsencrypt \
    -v ${BASE_PATH}/${PRODUCT_NAME}/www/:/usr/share/nginx/html/ \
    certbot/certbot \
    certonly \
    --agree-tos \
    --webroot \
    --webroot-path=/usr/share/nginx/html/ \
    --email ${DEFAULT_MAIL} \
    --expand \
    --keep \
    -d ${DOMAIN} \
    -d ${EXPAND}
fi

sudo chmod -R 777 ${BASE_PATH}/${PRODUCT_NAME}/letsencrypt/
