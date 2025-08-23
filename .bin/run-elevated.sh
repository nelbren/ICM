#!/bin/bash

if [ "$EUID" -ne 0 ]; then
    echo "This script requires superuser privileges. Use sudo."
    exit 1
fi

if [ $# -ne 2 ]; then
    echo "Uso: $0 <IP_permitida> <INICIO|FIN>"
    exit 1
fi

ALLOW_IP="$1"
ACTION=$(echo "$2" | tr '[:lower:]' '[:upper:]')

# Ejecutar acción
case "$ACTION" in
    INICIO)
        ~/ICM/.bin/internet_disable.sh
        ;;
    FIN)
        ~/ICM/.bin/internet_enable.sh
        ;;
    *)
        echo "Acción no reconocida: $ACTION. Usa INICIO o FIN."
        exit 1
        ;;
esac
