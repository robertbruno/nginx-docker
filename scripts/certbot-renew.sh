#!/bin/sh

set -e

# Si la variable DEBUG existe, se mostraran las órdenes y sus argumentos mientras se ejecutan.
[ -n "${DEBUG:-}" ] && set -x

certbot \
    --verbose \
    --no-random-sleep-on-renew \
    --webroot-path /usr/share/nginx/html/ \
    --noninteractive \
    renew