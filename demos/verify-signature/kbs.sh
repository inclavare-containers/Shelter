#!/usr/bin/env bash

# Stop kbs if launched already
systemctl --user -q is-active kbs.service && \
    systemctl --user stop kbs

# Start kbs if it isn't launched
if [ -d "/tmp/kbs" ]; then
    rm -rf /tmp/kbs
fi

mkdir /tmp/kbs
mkdir /tmp/kbs/{repository,attestation-service}
cp demos/verify-signature/kbs/* /tmp/kbs

openssl genpkey -algorithm ed25519 > /tmp/kbs/private.key
openssl pkey -in /tmp/kbs/private.key -pubout -out /tmp/kbs/public.pub

systemd-run --user --description="KBS Testing Server" --unit="kbs" \
  -G /usr/local/libexec/shelter/kbs -c /tmp/kbs/config.toml && \
    echo "KBS service started"

sed '/kern_cmdline =/ s/"$/ KBS_URL=http:\/\/10.0.2.2:8080 PASSPHRASE_PATH=default\/shelter-demos\/passphrase"/' /etc/shelter.conf > /tmp/kbs/shelter.conf

if [ "$(toml get --toml-path /var/lib/shelter/images/shelter-demos/image_info.toml image_type)" = "disk" ]; then
    /usr/local/libexec/shelter/kbs-client \
      config --auth-private-key /tmp/kbs/private.key \
      set-resource \
        --resource-file /var/lib/shelter/images/shelter-demos/passphrase \
        --path default/shelter-demos/passphrase

    echo "Passphrase configured for disk image decryption"
fi
