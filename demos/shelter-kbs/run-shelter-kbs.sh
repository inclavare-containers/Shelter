#!/bin/bash

KBS_DIR="${KBS_DIR:-/usr/local/libexec/shelter/kbs}"
KBS_PORT="${KBS_PORT:-6773}"

d="$(mktemp -d /tmp/run-kbs-XXXXXX)"

openssl genpkey -algorithm ed25519 > "$d/private.key"
openssl pkey -in "$d/private.key" -pubout -out "$d/public.pub"

cat >"$d/policy.rego" <<EOF
package policy
default allow = true
EOF

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

cat >$d/build.conf <<EOF
binary=(/usr/local/libexec/shelter/kbs/kbs:/sbin/kbs)
file=($d/config.toml:/kbs/config.toml $d/policy.rego:/kbs/policy.rego $d/public.pub:/kbs/public.pub)
EOF

shelter build \
  -t kbs-demo \
  -c "$d/build.conf" \
  -T initrd

conf=/etc/shelter.conf

# KBS running in shelter doesn't require to connect another KBS
if grep -q KBS_URL= "$conf"; then
    sed "/kern_cmdline =/ s|KBS_URL=http://[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}:[0-9]\{1,5\}\+||" "$conf" > "$d/shelter.conf"
    conf="$d/shelter.conf"
fi

shelter run \
  -c "$conf" \
  -p ${KBS_PORT}:${KBS_PORT} \
  kbs-demo \
    /sbin/kbs -c /kbs/config.toml &

cat >"$d/passphrase.b64" <<EOF
kLbSC6kMBwxpvFtFR4QMVlrD3uLD5CIOmUmqqARLUS/x/5Zm7pKX7qDhtBEQA9Eh8+Drm2ux1jtJ
pier0/6Cpt58tLLL1zEBAeC9LKFHPoyoVyn6gu2SSjcCFa2WRK28Y/3k/QJgeRyywebJ3dgj02qX
gs3O8ZEvfZi+ujl63T4PGYWeM16yuP2sFh0OiMO7MTwe8Bx4Q2LmLX68fB4mBgXuyWGKq5ePn83N
WO7IODXqDVxgBUxb9cPpgC4TxZ41Bdy34c1G77uHUSFuplCeoRjq99BXgzgjYbLnvX8qxcuQd8PM
gGDLmNqDibAaraEpDCA+bHEKKRRq4SDM3KKTq1tP584mgKmikK1eMcxtVp02JPYkwBvXswYafXUL
DtIR4gmQLIutpH2CJo0ectlpwK+B3+aAXYbimd+ffQpt4Srj7uld36GnHwqncj+6S7X9PCketIRD
w8UED/VnC6N6ocIqwPAQ691BR1p/UrOucUQYBgXusGpkWPV8l1a6k3U24Vukq8ywFpQp7d9XfYwR
97VfbW4ut/bAmM6LQHPIdnAsEe/quaSXCCbmIf6TutiUdNjeRhHDJhjP6C3J6OjApjVcTjWP4uDq
jg7krbp5mkGnR1Ua7NGsN2XgrA0ZLf3dLiYkNEX9XrCsb157LjPUIhoVpImXpNWE9O5u8yG1NJT8
XAlm4V7r5bGzJMDwnrCIvRBzJiPOgojX78MyH4A1IHCTiUEa4D+I7uKeTlLxCEpDhJjq5FOoFH+5
cWb7POOX1Tz8feVD/OCjSam1A5OpMNb2aiyQ22Phjcwv9ygV9gOo7aOTFEPUoJZUy3NI+ToDahNP
q60mvxwnV4eFrpcDBsmdvFAssBngLxoFOxyGC0i59OprsbWZ6wCYSmH31OwpSUehOjQN+221euQC
Bd+Q/uAz05ObSa8ymhLY47kltG1SKo1DzU3IkgKjw0eX838uW1L4ckWw3pb14Dq3YYbyHb190mtK
IF0GCrgz1MjwQRANqGcOWNgySfCSfFtP4ZGs+3wcB/4ZWP08MZ5mm6Dls6uUSJu87+sJhCbwA5OQ
lYsLooEU8FnfMCFN8HtEb6SYLM+vjOVzmrrg17rFJO+rc9jzCIYeZ/4puCnEJlJY/DPw1/9XMGxL
LZ7dDLd/mx1HuxHUOoeFflSCl/6iEdfafGkmnChfthA5HPkg6ZHxXjhxIUJsS7f8/OSswTUrycKu
bHW+WMN53zmdiZUoXpQMGej/03XHYwskVgoIvs45weeB3fiHz17yPkRLMlTox4Amig2eHvBXsrxl
lWC73ceiQcqcNx2xzN17sjuzdhWwNxThS1HDk+y+bq+oET6U4yYPbIVlOzQstyd8bW//bzzwgw==
EOF
base64 -d "$d/passphrase.b64" >"$d/passphrase"
# TODO: use shred -u to delete
rm -f "$d/passphrase.b64"
chmod 600 "$d/passphrase"

# Await for KBS service getting ready
sleep 5

${KBS_DIR}/../kbs-client \
  --url http://127.0.0.1:${KBS_PORT} \
  config --auth-private-key "$d/private.key" \
  set-resource \
    --resource-file "$d/passphrase" \
    --path default/shelter/passphrase

shelter stop kbs-demo

# TODO: use shred -u to delete
rm -rf "$d"