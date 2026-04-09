#!/bin/bash

set -e

# If the DEBUG variable exists, the commands and their arguments will be displayed while they are executed.
[ -n "${DEBUG:-}" ] && set -x

export DEFAULT_MAIL=${default_mail:-"test@mail.com"}
export AWS_REGION=${AWS_REGION:-"us-east-1"}
export AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID:-""}
export AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY:-""}
export ALB_ARN=${ALB_ARN:-}
export ALB_LISTENER_PORT="443"
export TARGET_GROUP_ARN=${TARGET_GROUP_ARN:-}
export LOGFILE=${LOGFILE:-"/var/log/letsencrypt/letsencrypt.log"}


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

# Directory where the renewed certificates are located
export CERT_DIR=${CERT_DIR:-"/etc/letsencrypt/live"}

if [ ! -f $CERT_DIR ]; then
  mkdir -pv $CERT_DIR
fi

# List of domains (directory in CERT_DIR) to process
DOMAINS=($(ls $CERT_DIR))

if [ ${#DOMAINS[@]} -eq 0 ]; then
    echo "No domains found in $CERT_DIR"
    exit 1
fi

# clean logs
if [ -f $LOGFILE ]; then
  > "$LOGFILE"
fi

# Renew the certificates
OUTPUT=$(certbot \
    --verbose \
    --no-random-sleep-on-renew \
    --agree-tos \
    --webroot \
    --webroot-path=/usr/share/nginx/html/ \
    --email "$DEFAULT_MAIL" \
    renew 2>&1 | tee -a "$LOGFILE")

# Check if any certificate has been renewed
if echo "$OUTPUT" | grep -q "succeeded"; then
    echo "At least one certificate was renewed."
elif echo "$OUTPUT" | grep -q "No renewals"; then
    echo "No certificates were renewed."
    exit 1
else
    echo "There was an error during the renewal."
    echo "$OUTPUT"
    exit 2
fi


for DOMAIN in "${DOMAINS[@]}"; do
    EXIST="/etc/letsencrypt/live/$DOMAIN/"
    if [ -d "$EXIST" ]; then

    echo "Checking [/etc/letsencrypt/live/$DOMAIN/]"

    if [ -n "${AWS_ACCESS_KEY_ID}" ]; then

        CERT_FINGERPRINT=$(openssl x509 -in "$EXIST/cert.pem" -noout -fingerprint | cut -d'=' -f2 | tr -d ':')

        EXISTING_CERTS=$(aws acm list-certificates --query 'CertificateSummaryList[*].CertificateArn' --output text)

        EXISTS_CERT_ARN=
        for CERT_ARN in $EXISTING_CERTS; do
            EXISTING_FINGERPRINT=$(aws acm describe-certificate --certificate-arn "$CERT_ARN" --query 'Certificate.Fingerprint' --output text)
            if [ "$CERT_FINGERPRINT" == "$EXISTING_FINGERPRINT" ]; then
                echo "The certificate already exists in ACM with ARN: $CERT_ARN"
                EXISTS_CERT_ARN=$CERT_ARN
                break
            fi
        done

        if [ -n "$EXISTS_CERT_ARN" ]; then
            continue 
        fi

        echo "Importing certificate to aws acm..."

        CERT_ARN=$(aws acm import-certificate --region $AWS_REGION --certificate fileb:///etc/letsencrypt/live/$DOMAIN/cert.pem --certificate-chain fileb:///etc/letsencrypt/live/$DOMAIN/fullchain.pem --private-key fileb:///etc/letsencrypt/live/$DOMAIN/privkey.pem | jq -r .CertificateArn)
        if [ $? -ne 0 ]; then
            echo "Error importing certificate for domain $DOMAIN"
            exit 1
        fi

        echo "CERT_ARN: $CERT_ARN"

        # If a listener does not exist for port 443, create it
        #LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn "$ALB_ARN" --query 'Listeners[?Port==`443`].ListenerArn' --output text)
        LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn "$ALB_ARN"  --output text | grep 443 | awk '{print $2}')

        if [[ -z "$LISTENER_ARN" ]]; then
            echo "Creating listener for port 443..."
            aws elbv2 create-listener \
            --load-balancer-arn "$ALB_ARN" \
            --certificates CertificateArn=$CERT_ARN \
            --default-actions Type=forward,TargetGroupArn=$TARGET_GROUP_ARN \
            --protocol "HTTPS" \
            --port 443
        else
            echo "Associating certificate to listener..."
            aws elbv2 add-listener-certificates \
                --listener-arn "$LISTENER_ARN" \
                --certificates CertificateArn=$CERT_ARN
        fi
    fi
    else
    echo "File [/etc/letsencrypt/live/$DOMAIN/] not found"
    fi
done