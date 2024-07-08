#!/usr/bin/env bash

cd `dirname $0`

mkdir -p ./payload

cd ./payload

echo "This is an example file for integrity check." > example.txt
tar -czf archive.tar.gz example.txt
rm example.txt

openssl dgst -sha256 -sign ../keys/private_key.pem -out archive.tar.gz.sig archive.tar.gz

echo "Payload generated at `realpath .`"
