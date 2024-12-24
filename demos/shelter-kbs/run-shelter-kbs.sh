#!/bin/bash

KBS_DIR="${KBS_DIR:-/usr/local/libexec/shelter/kbs}"
KBS_PORT="${KBS_PORT:-6773}"

name=shelter-kbs-demo
passphrase_sample="run-${name}-passphrase"

d="$(mktemp -d "/tmp/run-${name}-XXXXXX")"
stop_kbs=0

trap_handler() {
    trap - SIGINT SIGTERM EXIT ERR

    local line_no="$1"
    local err=$2

    if [ ${err} -ne 0 ] && [ "${line_no}" != "1" ]; then
        echo "Error occurred on line ${line_no}, exit code: ${err}"
    fi

    if [ ${stop_kbs} -eq 1 ]; then
        shelter stop "${name}"
    fi

    # TODO: use shred -u to delete
    rm -rf "$d"

    exit ${err}
}

trap 'trap_handler $LINENO $?' SIGINT SIGTERM EXIT ERR

# Step 1: build the shelter KBS DEMO image

priv_key="$(KBS_DIR="${KBS_DIR}" \
  KBS_PORT="${KBS_PORT}" \
  NAME="${name}" \
  SALT="run-${name}-salt" \
  ITER=1000 \
  LOG_LEVEL=0 \
  ${KBS_DIR}/shelter/build-shelter-kbs.sh)"
if [ $? -ne 0 ]; then
    exit 1
fi

if [[ "${priv_key}" == Private\ Key:\ * ]]; then
    priv_key="${priv_key#*Private\ Key:\ }"
else
    echo "Failed to retrieve the private key"
    exit 1
fi

# Step 2: run the shelter KBS DEMO image

SHELTER_KBS=1 \
  KBS_PORT="${KBS_PORT}" \
  NAME="${name}" \
  ${KBS_DIR}/start-kbs

stop_kbs=1

# Step 3: configure and register the local KBS

passphrase="$(echo -ne "${passphrase_sample}" | xxd -p | tr -d "\n")"

echo -ne "${priv_key}" | xxd -p -r >"$d/private_key"

KBS_ADDRESS=10.0.2.2 \
  KBS_PORT="${KBS_PORT}" \
  KBS_DIR="${KBS_DIR}" \
  PASSPHRASE="${passphrase}" \
  PASSPHRASE_PATH="default/run-${name}/passphrase" \
  PRIVATE_KEY_PATH="$d/private_key" \
  ${KBS_DIR}/config-kbs >"$d/${name}.conf"

# Step 4: donwload passphrase

passphrase_hex="$(${KBS_DIR}/../kbs-client \
                    --url "http://127.0.0.1:${KBS_PORT}" \
                    get-resource \
                      --path "default/run-${name}/passphrase" | \
                  base64 -d | xxd -p | tr -d "\n")"

magic="$(echo -ne "${passphrase_hex}" | cut -c 1-8)"
# "ENCP" magic
if [ "${magic}" == "454e4350" ]; then
    encp="$(echo -ne "${passphrase_hex}" | xxd -p -r)"
    passphrase="$(${KBS_DIR}/encp-decoder "${encp}")"
else
    passphrase="${passphrase_hex}"
fi

if [ "$(echo -ne "${passphrase}" | xxd -p -r)" == "${passphrase_sample}" ]; then
    echo -e "\033[1;32mSucceed to retrieve the sample passphrase from shelter-kbs\033[0m"
    exit 0
else
    echo -e "\033[1;31mFailed to retrieve the sample passphrase from shelter-kbs\033[0m"
    exit 1
fi