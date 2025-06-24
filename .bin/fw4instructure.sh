#!/bin/bash

DOMAIN="unitechonduras.instructure.com"
PORT=443
DOMAIN2="du11hjcvx0uqb.cloudfront.net"

# TODO: WINDOWS Y MACOS
LOCALHOST="localhost"
PORT_IA1=11434
PORT_IA2=1234

RULE_ANCHOR="instructure_anchor"
#PF_RULES_FILE="/etc/pf.anchors/$RULE_ANCHOR"
ANCHOR_NAME="blockall"
ANCHOR_FILE="/etc/pf.anchors/${ANCHOR_NAME}"

echo "ANTES"
cat $ANCHOR_FILE
echo "-----"

function get_ips() {
    dig +short "$DOMAIN" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}'
}

function get_ip2s() {
    dig +short "$DOMAIN2" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}'
}

function add_rules() {
    echo "# Anchor rules for $DOMAIN" | sudo tee -a "$ANCHOR_FILE" > /dev/null
    for ip in $(get_ips); do
        echo "pass out proto tcp to $ip port $PORT keep state" | sudo tee -a "$ANCHOR_FILE" > /dev/null
        #echo "pass out proto tcp to $ip port $PORT" | sudo tee -a "$ANCHOR_FILE" > /dev/null
        #echo "pass in quick inet from $ip" | sudo tee -a "$ANCHOR_FILE" > /dev/null
    done

    echo "# Anchor rules for $DOMAIN2" | sudo tee -a "$ANCHOR_FILE" > /dev/null
    for ip in $(get_ip2s); do
        echo "pass out proto tcp to $ip port $PORT keep state" | sudo tee -a "$ANCHOR_FILE" > /dev/null
        #echo "pass out proto tcp to $ip port $PORT" | sudo tee -a "$ANCHOR_FILE" > /dev/null
        #echo "pass in quick inet from $ip" | sudo tee -a "$ANCHOR_FILE" > /dev/null
    done

    echo "$ANCHOR_FILE:"
    cat "$ANCHOR_FILE"
    echo "------------"

    echo $PF_RULES_FILE
    echo $RULE_ANCHOR
    #sudo pfctl -a "$RULE_ANCHOR" -f "$PF_RULES_FILE"
    #sudo pfctl -sr | grep "$DOMAIN"
    #sudo pfctl -sr | grep "$DOMAIN2"

    echo "♻️ Aplicando anchor '$ANCHOR_NAME' con pfctl..."
    sudo pfctl -a "$ANCHOR_NAME" -f "$ANCHOR_FILE"

    echo "📋 Reglas cargadas:"
    sudo pfctl -a "$ANCHOR_NAME" -sr

    echo "✅ Reglas agregadas y cargadas para $DOMAIN y $DOMAIN2"
}

function delete_rules() {
    sudo rm -f "$PF_RULES_FILE"
    sudo pfctl -a "$RULE_ANCHOR" -F rules
    echo "❌ Reglas eliminadas para $DOMAIN y $DOMAIN2"
}

case "$1" in
    add)
        add_rules
        ;;
    delete)
        #delete_rules
        ;;
    *)
        echo "Uso: $0 {add|delete}"
        exit 1
        ;;
esac
