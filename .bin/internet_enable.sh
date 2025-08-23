#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "This script requires superuser privileges. Use sudo."
    exit 1
fi

ANCHOR_NAME="blockall"
ANCHOR_FILE="/etc/pf.anchors/${ANCHOR_NAME}"
PF_CONF="/etc/pf.conf"

echo "Disabling lock pf..."

pfctl -d

rm -f "$ANCHOR_FILE"

echo "Blocking disabled. Full internet access restored."

read x