#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <public_key.pem> <signature.sig> <archive.tar.gz>"
    exit 1
fi

PUBLIC_KEY=$1
SIGNATURE=$2
ARCHIVE=$3

openssl dgst -verify $PUBLIC_KEY -signature $SIGNATURE $ARCHIVE

if [ $? -eq 0 ]; then
    echo "Signature verified successfully."
else
    echo "Signature verification failed."
fi

