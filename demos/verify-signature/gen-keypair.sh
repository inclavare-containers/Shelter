#!/usr/bin/env bash

cd `dirname $0`

mkdir -p ./keys

openssl genrsa -out ./keys/private_key.pem 2048
openssl rsa -in ./keys/private_key.pem -pubout -out ./keys/public_key.pem

echo -e "\033[1;32mKeys generated at $(realpath keys)\033[0m"