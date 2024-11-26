#!/bin/bash

set -e

# If the DEBUG variable exists, the commands and their arguments will be displayed while they are executed.
[ -n "${DEBUG:-}" ] && set -x

export DEFAULT_MAIL=${default_mail:-""}
export AWS_REGION=${AWS_REGION:-"us-east-1"}
export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-""}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:-""}
export ALB_ARN=${ALB_ARN:-}
export ALB_LISTENER_PORT="443"
export TARGET_GROUP_ARN=${TARGET_GROUP_ARN:-}

# Directory where the renewed certificates are located
export CERT_DIR=${CERT_DIR:-"/etc/letsencrypt/live"}

# List of domains (directory in CERT_DIR) to process
DOMAINS=($(ls $CERT_DIR))


usage="
$(basename "$0") [-m mail]

Create o expand a certificated

where:
    -h  show this help text
    -m  mail to notify. [ej.: jhosnsmith@mail.com]
"

while getopts ":h:d:e:m:" opt; do
  case ${opt} in
    h)
      printf $usage
      exit 1
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


if [ -z "${DEFAULT_MAIL}" ]; then
    echo "the parameter default_mail is missing. ${usage}"
    exit 1
fi

# Renew the certificates
certbot \
    --verbose \
    --no-random-sleep-on-renew \
    --webroot-path /usr/share/nginx/html/ \
    --noninteractive \
    renew

for DOMAIN in "${DOMAINS[@]}"; do
    CERT_FILE="$CERT_DIR/$DOMAIN/fullchain.pem"
    KEY_FILE="$CERT_DIR/$DOMAIN/privkey.pem"
    
    if [ -f "$CERT_FILE" ] && [ -f "$KEY_FILE" ]; then
        echo "Uploading certificates to AWS ACM only if they do not exist..."

        CERT_ARN=$(aws acm list-certificates --region "$AWS_REGION" --query "CertificateSummaryList[?DomainName=='$DOMAIN'].CertificateArn" --output text)
        if [ -z "$CERT_ARN" ]; then
            CERT_ARN=$(aws acm import-certificate \
                --region "$AWS_REGION" \
                --certificate fileb://"$CERT_FILE" \
                --private-key fileb://"$KEY_FILE" \
                --query "CertificateArn" \
                --output text)
            echo "Imported certificate for $DOMAIN: $CERT_ARN"
        else
            echo "Certificate already exists for $DOMAIN: $CERT_ARN"
        fi

        echo "Update the ALB listener with the new certificate..." 
        aws elbv2 modify-listener \
            --region "$AWS_REGION" \
            --listener-arn "$ALB_ARN" \
            --port "$ALB_LISTENER_PORT" \
            --protocol HTTPS \
            --default-actions Type=forward,TargetGroupArn="$TARGET_GROUP_ARN" \
            --certificates CertificateArn="$CERT_ARN"
        
        echo "Updated listener for $DOMAIN with $CERT_ARN certificate"
    else
        echo "Certificate for $DOMAIN not found in $CERT_DIR"
    fi
done
