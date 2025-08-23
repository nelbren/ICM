#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Uso: $0 <IP_permitida> <INICIO|FIN>"
    exit 1
fi

ALLOW_IP="$1"
ACTION=$(echo "$2" | tr '[:lower:]' '[:upper:]')

case "$ACTION" in
    INICIO)
        echo "DOING INICIO"
        ~/ICM/.bin/internet_disable.sh $ALLOW_IP
        ;;
    FIN)
        echo "DOING FIN"
        ~/ICM/.bin/internet_enable.sh
        ;;
    *)
        echo "Unrecognized action: $ACTION. Use INCIO or FIN."
        exit 1
        ;;
esac
