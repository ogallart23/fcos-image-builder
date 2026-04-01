#!/bin/sh
set -eu

LOG=/run/ignition-convert.log
exec >>"$LOG" 2>&1

echo "[convert] starting"

# trobar vmtoolsd
VMTOOLSD=/usr/bin/vmtoolsd

if [ ! -x "$VMTOOLSD" ]; then
    echo "vmtoolsd not found, skipping ignition preconvert" > /dev/kmsg
    exit 0
fi

echo "vmtoolsd found at $VMTOOLSD" > /dev/kmsg

echo "[convert] using $VMTOOLSD"

# obtenir ignition v2
DATA="$("$VMTOOLSD" --cmd "info-get guestinfo.ignition.config.data" || true)"

if [ -z "$DATA" ] || [ "$DATA" = "{}" ]; then
    echo "[convert] no guestinfo ignition data or empty JSON"
    exit 0
fi

if ! echo "$DATA" | base64 -d > /run/ignitionv2.json 2>/dev/null; then
    echo "[convert] guestinfo data is not valid base64, skipping"
    exit 0
fi

# convertir a v3
if ! /usr/bin/ign-converter \
        --input /run/ignitionv2.json \
        --output /run/ignition.json; then
    echo "[convert] ign-converter failed, skipping"
    exit 0
fi

ENCODED=$(base64 -w0 /run/ignition.json)
"$VMTOOLSD" --cmd "info-set guestinfo.ignition.config.data $ENCODED"
echo "[convert] updated guestinfo.ignition.config.data with v3"