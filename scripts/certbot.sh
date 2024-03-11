#!/bin/bash

DEFAULT_MAIL=${DEFAULT_MAIL:-""}
EXPAND=${EXPAND:-}
DOMAIN=${DOMAIN:-}

usage="
$(basename "$0") [-d domain] [-e expand]

Create o expand a certificated

where:
    -h  show this help text
    -d  domain name to create or expand
    -e  space separate list of domain to add to the primary domain.
    -m  mail to notify
"

while getopts ":h:d:e:m:" opt; do
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
    m )
      DEFAULT_MAIL=$OPTARG
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


if [[ -z "$EXPAND" ]]; then
    echo "Sigle domain ${DOMAIN}"
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
