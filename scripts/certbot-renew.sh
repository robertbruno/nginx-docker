#!/bin/sh

set -e

# If the DEBUG variable exists, the commands and their arguments will be displayed while they are executed.
[ -n "${DEBUG:-}" ] && set -x

certbot \
    --verbose \
    --no-random-sleep-on-renew \
    --webroot-path /usr/share/nginx/html/ \
    --noninteractive \
    renew