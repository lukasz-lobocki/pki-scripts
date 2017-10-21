#!/bin/bash 
# Generates an intermediate CA using the connected yubikey
# This requires a root certificate yubikey to sign the new intermediate

# Load common components
. ./common.sh

# Check input count
if [ "$#" -ne 2 ]; then 
    echo "Usage: $0 MODE FILE"
    echo "MODE - local for local certificate, yubikey for yubikey based certificate"
    echo "FILE - intermediate certificate file name"
    exit
fi

MODE=$1
FILE=$2

if [ "$MODE" != "local" ] && [ "$MODE" != "yubikey" ]; then
    echo "Unrecognised mode (expected local or yubikey)"
    exit
fi

echo "Generating new intermediate cert: $NAME"

echo "Configuring intermediate cert from ./int.conf.in"
fcfg --input=int.conf.in --output=$DIR/$FILE.conf --config=site.yml -v=FileName:$FILE -vPrivateKey:$FILE -vPathLen:0 --quiet

echo "Generating intermediate key"
openssl genrsa -out $DIR/$FILE.key $KEYLEN

echo "Generating intermediate CSR"
prepare_files $DIR/$FILE
openssl req -new -config $DIR/$FILE.conf -key $DIR/$FILE.key -out $DIR/$FILE.csr 

read -p "Insert root yubikey and press enter to continue..."

echo "Fetching yubikey CA cert"
yk_fetch $DIR/yk-ca.crt $DIR/yk-ca.srl

echo "Signing intermediate certificate"
yk_sign_ca $DIR/yk-ca.crt $DIR/$FILE.csr $DIR/$FILE.conf $DIR/$FILE.crt

echo "Created intermediate certificate: $DIR/$FILE.crt"

# Load cert and key in yubikey mode
if [ "$MODE" = "yubikey" ]; then
    read -p "Insert new intermediate yubikey and press enter to continue..."

    yk_load $DIR/$FILE.crt $DIR/$FILE.key

    rm $DIR/$FILE.key
fi
