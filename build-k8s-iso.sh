#!/usr/bin/env bash
set -euo pipefail

cosas() {
    local -r COREOS_ASSEMBLER_CONTAINER_LATEST="quay.io/coreos-assembler/coreos-assembler:latest"

    if [[ -z "${COREOS_ASSEMBLER_CONTAINER:-}" ]] && podman image exists "${COREOS_ASSEMBLER_CONTAINER_LATEST}"; then
        local cosa_build_date_str
        cosa_build_date_str=$(podman inspect -f '{{.Created}}' "${COREOS_ASSEMBLER_CONTAINER_LATEST}" | awk '{print $1}')
        local cosa_build_date
        cosa_build_date=$(date -d "${cosa_build_date_str}" +%s)
        if [[ $(date +%s) -ge $((cosa_build_date + 60*60*24*7)) ]]; then
            echo "COSA container image may be outdated. Consider pulling a newer version."
            sleep 5
        fi
    fi

    podman run --rm --security-opt=label=disable --privileged \
        -v "${PWD}:/srv" \
        --device=/dev/kvm --device=/dev/fuse \
        --tmpfs=/tmp -v /var/tmp:/var/tmp \
        --name cosa \
        ${COREOS_ASSEMBLER_CONFIG_GIT:+-v=$COREOS_ASSEMBLER_CONFIG_GIT:/srv/src/config/:ro} \
        ${COREOS_ASSEMBLER_GIT:+-v=$COREOS_ASSEMBLER_GIT/src/:/usr/lib/coreos-assembler/:ro} \
        ${COREOS_ASSEMBLER_ADD_CERTS:+-v=/etc/pki/ca-trust:/etc/pki/ca-trust:ro} \
        ${COREOS_ASSEMBLER_CONTAINER_RUNTIME_ARGS:-} \
        ${COREOS_ASSEMBLER_CONTAINER:-$COREOS_ASSEMBLER_CONTAINER_LATEST} "$@"
}

BUILD_DIR="build"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

cosas init --branch stable https://github.com/coreos/fedora-coreos-config --force
cd ..

DEST="build/src/config"
mkdir -p "$DEST"

cp .containerignore "$DEST/.containerignore"
cp Containerfile.k8s-base "$DEST/Containerfile"
cp -r kube "$DEST"
cp -r repos "$DEST"

cd build

cosas build --version=stable
cosas buildextend-live

img=$(find builds/latest/x86_64/ -name "*.iso" | head -n1)
mv "$img" ../fcos-k8s.iso
