#!/usr/bin/env bash

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <public_key.pem> <signature.sig> <archive.tar.gz>"
    exit 1
fi

PUBLIC_KEY=$1
SIGNATURE=$2
ARCHIVE=$3

openssl dgst -verify $PUBLIC_KEY -signature $SIGNATURE $ARCHIVE

if [ $? -eq 0 ]; then
    echo -e "\033[1;32mSignature verified successfully.\033[0m"
else
    echo "\033[1;31mSignature verification failed.\033[0m"
fi