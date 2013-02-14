#!/bin/bash
set -eu

function print_usage_and_quit
{
cat << USAGE >&2
usage: $(basename $0) ISOFILE XENSERVER NETWORK_NAME MACHINE_NAME

Upload an iso file, and import it as an sr

Positional arguments:
 ISOFILE - iso file
 XENSERVER - a xenserver/xcp host
 NETWORK_NAME - the network to connect to
 MACHINE_NAME - the name of the machine to start
USAGE
exit 1
}

function stage
{
STG="$1"
SRC=$(readlink -f "$2")
TGT="$3"
(
    cd "$STG"
    ln -s "$SRC" "$TGT"
)
}

function create_archive
{
STAGING_DIR=$(mktemp -d)
stage "$STAGING_DIR" "$1" customxs.iso
stage "$STAGING_DIR" "$2" starter.sh
(
    cd "$STAGING_DIR"
    tar -chzf - ./
)
rm -rf $STAGING_DIR
}

ISO_FILE="${1-$(print_usage_and_quit)}"
XENSERVER="${2-$(print_usage_and_quit)}"
NETWORK_NAME="${3-$(print_usage_and_quit)}"
MACHINE_NAME="${4-$(print_usage_and_quit)}"

THIS_DIR=$(dirname $(readlink -f $0))
create_archive "$ISO_FILE" "$THIS_DIR/_xs_vm_starter.sh" |
ssh "root@$XENSERVER" "mkdir vh && cd vh && tar -xzf - && bash starter.sh $NETWORK_NAME $MACHINE_NAME && cd .. && rm -rf vh"
