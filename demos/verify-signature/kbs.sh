#!/usr/bin/env bash

## stop kbs if it is active and return immediately
systemctl --user -q is-active kbs.service && \
systemctl --user stop kbs && \
echo "stop kbs service" && \
exit 0

## start kbs if it isn't active
if [ -d "/tmp/kbs" ]; then
    rm -r /tmp/kbs
fi

mkdir /tmp/kbs
mkdir /tmp/kbs/{repository,attestation-service}
cp demos/verify-signature/kbs/* /tmp/kbs/

openssl genpkey -algorithm ed25519 > /tmp/kbs/private.key
openssl pkey -in /tmp/kbs/private.key -pubout -out /tmp/kbs/public.pub

systemd-run --user --description="kbs test server" --unit="kbs" -G /usr/local/libexec/shelter/kbs -c /tmp/kbs/config.toml && \
echo "start kbs"


if [ "$(toml get --toml-path /var/lib/shelter/images/shelter-demos/image_info.toml image_type)" = "disk" ]; then
    sleep 5

    /usr/local/libexec/shelter/kbs-client \
    config --auth-private-key /tmp/kbs/private.key \
    set-resource --resource-file /var/lib/shelter/images/shelter-demos/passphrase \
    --path default/shelter-demos/passphrase

    echo "upload passphrase"
fi