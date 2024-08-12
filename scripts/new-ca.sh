#!/bin/bash
# Create a new CA

if [ $# -ne 2 ]; then
    echo "Usage: $0 <ROOT_NAME> <\"Human Name\">"
    exit
fi

# Setup variables
export ROOT_NAME=$1
export HUMAN_NAME=$2
export DIR=$ROOT_NAME

set -e

# Load config
source $DIR/config

# Load helpers
source ./scripts/common.sh

# Create a working directory and required files
touch $DIR/$ROOT_NAME.db

if [ ! -f "$DIR/$ROOT_NAME.srl" ]; then
    echo "01" > $DIR/$ROOT_NAME.srl
fi

# Then, generate a root key
echo "Generating key: $DIR/$ROOT_NAME.key"
generate_key $DIR/$ROOT_NAME.key

# Copy (and edit!) the root certificate configuration template
echo "Generating configuration: $DIR/$ROOT_NAME.conf"
configure_file templates/root.conf $DIR/$ROOT_NAME.conf "$HUMAN_NAME"

# Generate a Certificate Signing Request (CSR)
echo "Generating CSR: $DIR/$ROOT_NAME.csr"
openssl req -new -config $DIR/$ROOT_NAME.conf -key $DIR/$ROOT_NAME.key -out $DIR/$ROOT_NAME.csr

# Self-sign the certificate request
echo "Generating Certificate: $DIR/$ROOT_NAME.crt"
openssl ca -selfsign -days $CA_EXPIRY_DAYS -config $DIR/$ROOT_NAME.conf -in $DIR/$ROOT_NAME.csr -out $DIR/$ROOT_NAME.certificate -batch

# Generate a PEM from the certificate file output
echo "Generating PEM: $DIR/$ROOT_NAME.pem"
openssl x509 -in $DIR/$ROOT_NAME.certificate -outform pem -out $DIR/$ROOT_NAME.crt

# Generate fingerprint if step is installed
openssl x509 -in $DIR/$ROOT_NAME.crt -fingerprint -sha256 -noout | tee $DIR/$ROOT_NAME.fng

# All done!
echo "Generated new CA: $DIR/$ROOT_NAME.crt $DIR/$ROOT_NAME.pem"
