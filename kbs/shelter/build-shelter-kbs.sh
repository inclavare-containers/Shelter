#!/bin/bash

KBS_DIR="${KBS_DIR:-/usr/local/libexec/shelter/kbs}"
KBS_PORT="${KBS_PORT:-6773}"
NAME="${NAME:-shelter-kbs}"
PASSPHRASE="${PASSPHRASE:-}"
PASSPHRASE_PATH="${PASSPHRASE_PATH:-default/shelter/passphrase}"

salt="shelter-kbs-salt"
iter=1000

d="$(mktemp -d /tmp/build-shelter-kbs-XXXXXX)"

trap_handler() {
    trap - SIGINT SIGTERM EXIT ERR

    local line_no="$1"
    local err=$2

    if [ ${err} -ne 0 ] && [ "${line_no}" != "1" ]; then
        echo "Error occurred on line ${line_no}, exit code: ${err}"
    fi

    # TODO: use shred -u to delete
    rm -rf "$d"

    exit ${err}
}

trap 'trap_handler $LINENO $?' SIGINT SIGTERM EXIT ERR

# Step 1: build and run cbmkpasswd to generate the IKM based on
# shelter itself

if [ -n "${PASSPHRASE}" ]; then
    cat >"$d/build-cbmkpasswd.conf" <<EOF
binary=(/usr/local/libexec/shelter/cbmkpasswd:/sbin/cbmkpasswd)
EOF

    shelter build \
      -t cbmkpasswd \
      -T initrd \
      -c "$d/build-cbmkpasswd.conf" || {
        echo "Failed to build cbmkpasswd image"
        exit 1
      }

    # KBS running in shelter doesn't require to connect another KBS
    conf=/etc/shelter.conf
    if grep -q KBS_URL= "${conf}" 2>/dev/null; then
        sed "/kern_cmdline =/ s|KBS_URL=http://[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}:[0-9]\{1,5\}\+||" \
          "${conf}" > "$d/shelter.conf"
        conf="$d/shelter.conf"
    fi

    # Generate IKM
    ikm="$(LOG_LEVEL=0 shelter run \
      -c "${conf}" \
      cbmkpasswd -- \
      "cbmkpasswd --salt "${salt}" --iter "${iter}" -n 256")"
    if [ $? -ne 0 ]; then
        echo "Failed to run cbmkpasswd image"
        exit 1
    fi
    if [ $(echo -ne "${ikm}" | wc -c) -ne 512 ]; then
        echo "Invalid length of ikm"
        exit 1
    fi

    # Step 2: generate encrypted passphrase bundle

    encp="$(${KBS_DIR}/shelter/encp-encoder "${PASSPHRASE}" "${ikm}")"
    if [ $? -ne 0 ]; then
        echo "Failed to generate encrypted passphrase bundle"
        exit 1
    fi

    echo -ne "${encp}" >"$d/passphrase.encp"
fi

# Step 3: build KBS image

openssl genpkey -algorithm ed25519 >"$d/private.key"
openssl pkey -in "$d/private.key" -pubout -out "$d/public.pub"

cat >"$d/config.toml" <<EOF
insecure_http = true
insecure_api = true
sockets = ["0.0.0.0:${KBS_PORT}"]
auth_public_key = "/kbs/public.pub"

[attestation_token_config]
attestation_token_type = "CoCo"

[repository_config]
type = "LocalFs"
dir_path = "/kbs/repository"

[as_config]
work_dir = "/kbs/attestation-service"
policy_engine = "opa"
attestation_token_broker = "Simple"

[as_config.attestation_token_config]
duration_min = 5

[as_config.rvps_config]
store_type = "LocalFs"
remote_addr = ""

[policy_engine_config]
policy_path = "/kbs/policy.rego"
EOF

# Note that the passphrase is provisioned during the build, instead of
# using kbs-client to register the passphrase as a resource during the
# runtime.
if [ -n "${PASSPHRASE}" ]; then
    cat >"$d/build-shelter-kbs.conf" <<EOF
binary=(/usr/local/libexec/shelter/kbs/kbs:/sbin/kbs)
file=($d/config.toml:/kbs/config.toml ${KBS_DIR}/policy.rego:/kbs/policy.rego $d/public.pub:/kbs/public.pub $d/passphrase.encp:/kbs/repository/${PASSPHRASE_PATH})
EOF
else
    cat >"$d/build-shelter-kbs.conf" <<EOF
binary=(/usr/local/libexec/shelter/kbs/kbs:/sbin/kbs)
file=($d/config.toml:/kbs/config.toml ${KBS_DIR}/policy.rego:/kbs/policy.rego $d/public.pub:/kbs/public.pub)
EOF
fi

shelter build \
  -t "${NAME}" \
  -c "$d/build-shelter-kbs.conf" \
  -T initrd || {
    echo "Failed to build ${NAME} image"
    exit 1
  }

if [ -n "${PASSPHRASE}" ]; then
    echo "IKM: ${ikm}" >&2
fi

echo "Private Key: $(cat "$d/private.key" | xxd -p | tr -d "\n")"