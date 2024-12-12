#!/usr/bin/env bash

KBS_DIR=/usr/local/libexec/shelter/kbs

# Stop kbs if launched already
systemctl --user -q is-active kbs.service && \
    systemctl --user stop kbs

if [ ! -d "${KBS_DIR}" ]; then
    mkdir -p "${KBS_DIR}"
fi

[ ! -s "${KBS_DIR}/private.key" ] && \
    openssl genpkey -algorithm ed25519 > ${KBS_DIR}/private.key
[ ! -s "${KBS_DIR}/public.pub" ] && \
    openssl pkey -in ${KBS_DIR}/private.key -pubout -out "${KBS_DIR}/public.pub"

[ -z "${KBS_ADDRESS}" ] && KBS_ADDRESS=10.0.2.2
[ -z "${KBS_PORT}" ] && KBS_PORT=8080

# 10.0.2.2 indicates the gateway/host IP used in QEMU user network SLIRP
pattern="/kern_cmdline =/ s/\"$/ ${kbs_cmdline}\"/"
if [ "$KBS_ADDRESS" != "10.0.2.2" ]; then
    sed "/sockets =/ s/KBS_ADDRESS:KBS_PORT/${KBS_ADDRESS}:${KBS_PORT}/" "$KBS_DIR/config.toml.template" > "$KBS_DIR/config.toml"
else
    sed "/sockets =/ s/KBS_ADDRESS:KBS_PORT/127.0.0.1:${KBS_PORT}/" "$KBS_DIR/config.toml.template" > "$KBS_DIR/config.toml"
fi

systemd-run --user --description="KBS Server" --unit="kbs" \
  -G "${KBS_DIR}/kbs" -c "${KBS_DIR}/config.toml" && \
    echo "KBS service started"

kbs_cmdline="KBS_URL=http://${KBS_ADDRESS}:${KBS_PORT}"

if [ -s "${PASSPHRASE}" ]; then
    # Await for KBS service getting ready
    sleep 5

    ${KBS_DIR}/../kbs-client \
      config --auth-private-key "${KBS_DIR}/private.key" \
      set-resource \
        --resource-file "${PASSPHRASE}" \
        --path default/shelter/passphrase

    kbs_cmdline="$kbs_cmdline PASSPHRASE_PATH=default/shelter/passphrase"
fi

# Tune into the sed pattern
pattern="$(echo $kbs_cmdline | sed 's|/|\\/|g')"
pattern="/kern_cmdline =/ s/\"$/ ${pattern}\"/"
sed "$pattern" /etc/shelter.conf > "${KBS_DIR}/shelter.conf"

echo -e "\033[1;31mPlease execute \"shelter run -c ${KBS_DIR}/shelter.conf\", or append \"$kbs_cmdline\" in the \"kern_cmdline\" line in your shelter.conf.\033[0m"