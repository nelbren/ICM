#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "This script requires superuser privileges. Use sudo."
    exit 1
fi

if [ $# -ne 1 ]; then
    echo "Uso: $0 <ICMd_IP>"
    exit 1
fi

ALLOW_IP="$1"

DEFAULT_IFACE=$(route -n get default 2>/dev/null | awk '/interface:/ { print $2 }')

if [ -z "$DEFAULT_IFACE" ]; then
    DEFAULT_IFACE=en0
    echo "The active network interface could not be detected. Using: $DEFAULT_IFACE"
    exit 1
fi

ANCHOR_NAME="blockall"
ANCHOR_FILE="/etc/pf.anchors/${ANCHOR_NAME}"
PF_CONF="/etc/pf.conf"

echo "Configuring pf to only allow access to $ALLOW_IP on the $DEFAULT_IFACE interface"
    
cat <<EOF > "$ANCHOR_FILE"
block out all
block in all
pass out proto tcp to $ALLOW_IP port 8080
pass in quick inet from $ALLOW_IP
EOF

if ! grep -q "anchor \"$ANCHOR_NAME\"" "$PF_CONF"; then
    echo "anchor \"$ANCHOR_NAME\"" >> "$PF_CONF"
    echo "load anchor \"$ANCHOR_NAME\" from \"$ANCHOR_FILE\"" >> "$PF_CONF"
fi

# ls -l ~/ICM/.bin/fw4instructure.sh
# ~/ICM/.bin/fw4instructure.sh add
# echo SALIDA: $?

echo "♻️ Reloading anchor '$ANCHOR_NAME'..."
pfctl -a "$ANCHOR_NAME" -f "$ANCHOR_FILE"

# Verificar y aplicar configuración
pfctl -nf "$PF_CONF" || { echo "Error en la configuración de pf."; exit 1; }

pfctl -f "$PF_CONF"
pfctl -e
echo "Bloqueo activado. Solo $ALLOW_IP tiene salida."

read x