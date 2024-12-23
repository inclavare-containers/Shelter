#!/usr/bin/env bash

# Parameters required for SHELTER_KBS=0
KBS_DIR="${KBS_DIR:-/usr/local/libexec/shelter/kbs}"
PASSPHRASE="${PASSPHRASE:-}"
KBS_ADDRESS="${KBS_ADDRESS:-127.0.0.1}"
# Parameters required for SHELTER_KBS=1
KBS_PORT="${KBS_PORT:-6773}"
SHELTER_KBS="${SHELTER_KBS:-0}"

d=/var/run/kbs
if [ ! -d "$d" ]; then
    sudo sh -c "mkdir -p \"$d\""
fi

trap_handler() {
    trap - SIGINT SIGTERM EXIT ERR

    local line_no="$1"
    local err=$2

    if [ ${err} -ne 0 ] && [ "${line_no}" != "1" ]; then
        echo "Error occurred on line ${line_no}, exit code: ${err}"
    fi

    if [ ${SHELTER_KBS} -eq 0 ] && [ ${err} -ne 0 ]; then
        systemctl --user stop kbs.service

        # TODO: use shred -u to delete
        sudo sh -c "rm -rf \"$d\""
    fi

    exit ${err}
}

trap 'trap_handler $LINENO $?' SIGINT SIGTERM EXIT ERR

if [ ${SHELTER_KBS} -eq 1 ]; then
    # Stop KBS service if launched already
    shelter stop local-kbs 2>/dev/null

    conf=/etc/shelter.conf
    kbs_conf="${conf}"

    # KBS running in shelter doesn't require to connect another KBS
    if grep -q KBS_URL= "${conf}"; then
        kbs_conf="$d/shelter-kbs.conf"
        sudo sh -c \
          "sed \"/kern_cmdline =/ s|KBS_URL=\S*||g\" \"${conf}\" >\"${kbs_conf}\""
    fi

    shelter run \
      -c "${kbs_conf}" \
      -p ${KBS_PORT}:${KBS_PORT} \
      local-kbs \
        /sbin/kbs -c /kbs/config.toml &

    # Await for KBS service getting ready
    sleep 5

    exit 0
fi

# Stop KBS service if launched already
systemctl --user -q is-active kbs.service && \
  systemctl --user stop kbs.service

[ ! -s "${KBS_DIR}/private.key" ] && \
    sudo sh -c "openssl genpkey -algorithm ed25519 >\"${KBS_DIR}/private.key\""
[ ! -s "${KBS_DIR}/public.pub" ] && \
    sudo sh -c "openssl pkey -in ${KBS_DIR}/private.key -pubout -out \"${KBS_DIR}/public.pub\""

if [ "${KBS_ADDRESS}" == "127.0.0.1" ]; then
    listen_address=127.0.0.1
else
    listen_address=0.0.0.0
fi

sudo sh -c "sed \"/sockets =/ s/KBS_ADDRESS:KBS_PORT/${listen_address}:${KBS_PORT}/\" \"${KBS_DIR}/config.toml.template\" > \"$d/config.toml\""

systemd-run --user --description="KBS Server" --unit="kbs" \
  -G "${KBS_DIR}/kbs" -c "$d/config.toml" && \
  echo "KBS service started" || {
    echo "Failed to start KBS service"
    exit 1
  }

# Await for KBS service getting ready
sleep 5