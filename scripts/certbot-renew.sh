#!/bin/sh

certbot \
    --verbose \
    --no-random-sleep-on-renew \
    --webroot-path /usr/share/nginx/html/ \
    --noninteractive \
    renew