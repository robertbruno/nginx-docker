#!/bin/bash

set -e

# Configuration
export AWS_REGION=${AWS_REGION:-"us-east-1"}
export ALB_ARN=${ALB_ARN:-""}  # ARN of the Application Load Balancer
export LOGFILE=${LOGFILE:-"/var/log/letsencrypt/delete-expired-certificates.log"}

# Verify that ALB_ARN is defined
if [ -z "$ALB_ARN" ]; then
    echo "Error: ALB_ARN is not defined."
    exit 1
fi

# Function to remove a certificate from ALB listeners
function remove_certificate_from_listeners() {
    local CERTIFICATE_ARN=$1
    echo "Removing certificate $CERTIFICATE_ARN from ALB listeners..."

    # Get all listeners for the ALB
    LISTENERS=$(aws elbv2 describe-listeners --load-balancer-arn "$ALB_ARN" --query 'Listeners[*].ListenerArn' --output text)

    for LISTENER_ARN in $LISTENERS; do
        echo "Checking listener $LISTENER_ARN..."

        # Get certificates associated with the listener
        CERTIFICATES=$(aws elbv2 describe-listener-certificates --listener-arn "$LISTENER_ARN" --query 'Certificates[*].CertificateArn' --output text)

        for CERT_ARN in $CERTIFICATES; do
            if [ "$CERT_ARN" == "$CERTIFICATE_ARN" ]; then
                echo "Removing certificate $CERTIFICATE_ARN from listener $LISTENER_ARN..."
                aws elbv2 remove-listener-certificates \
                    --listener-arn "$LISTENER_ARN" \
                    --certificates CertificateArn="$CERTIFICATE_ARN"
                echo "Certificate removed successfully."
            fi
        done
    done
}

# Function to delete a certificate from ACM
function delete_certificate() {
    local CERTIFICATE_ARN=$1
    echo "Deleting certificate $CERTIFICATE_ARN from ACM..."
    aws acm delete-certificate --certificate-arn "$CERTIFICATE_ARN"
    echo "Certificate deleted successfully."
}

# Get the current date in UTC format
CURRENT_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Get all certificates from ACM
echo "Fetching list of certificates from ACM..."
CERTIFICATES=$(aws acm list-certificates --query 'CertificateSummaryList[*].CertificateArn' --output text)

# Process each certificate
for CERTIFICATE_ARN in $CERTIFICATES; do
    echo "Processing certificate: $CERTIFICATE_ARN"

    # Get the expiration date of the certificate
    EXPIRATION_DATE=$(aws acm describe-certificate --certificate-arn "$CERTIFICATE_ARN" --query 'Certificate.NotAfter' --output text)

    # Check if the certificate is expired
    if [[ "$EXPIRATION_DATE" < "$CURRENT_DATE" ]]; then
        echo "Expired certificate found: $CERTIFICATE_ARN (Expiration: $EXPIRATION_DATE)"

        # Remove the certificate from ALB listeners
        remove_certificate_from_listeners "$CERTIFICATE_ARN"

        # Delete the certificate from ACM
        delete_certificate "$CERTIFICATE_ARN"
    else
        echo "Valid certificate: $CERTIFICATE_ARN (Expiration: $EXPIRATION_DATE)"
    fi
done

echo "Process completed."