#!/bin/sh

certbot/certbot \
    --no-random-sleep-on-renew \
    --webroot-path /usr/share/nginx/html/ \
    --noninteractive \
    renew