#!/bin/sh

set -e

# If the DEBUG variable exists, the commands and their arguments will be displayed while they are executed.
[ -n "${DEBUG:-}" ] && set -x

REASON=${reason:-"superseded"}
DOMAIN=${domain:-}

certbot revoke -n \
  --verbose \
  --non-interactive \
  --cert-path /etc/letsencrypt/live/${DOMAIN}/cert.pem \
  --reason ${REASON}
