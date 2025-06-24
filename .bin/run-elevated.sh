#!/bin/bash

# Verificación de privilegios
if [ "$EUID" -ne 0 ]; then
    echo "Este script requiere privilegios de superusuario. Usa sudo."
    exit 1
fi

# Verifica parámetros
if [ $# -ne 2 ]; then
    echo "Uso: $0 <IP_permitida> <INICIO|FIN>"
    exit 1
fi

ALLOW_IP="$1"
ACTION=$(echo "$2" | tr '[:lower:]' '[:upper:]')

# Detectar interfaz activa de salida
DEFAULT_IFACE=$(route -n get default 2>/dev/null | awk '/interface:/ { print $2 }')

if [ -z "$DEFAULT_IFACE" ]; then
    echo "No se pudo detectar la interfaz de red activa."
    exit 1
fi

ANCHOR_NAME="blockall"
ANCHOR_FILE="/etc/pf.anchors/${ANCHOR_NAME}"
PF_CONF="/etc/pf.conf"

function enable_blocking {
    echo "Configurando pf para permitir solo el acceso a $ALLOW_IP en la interfaz $DEFAULT_IFACE"

    # Crear anchor con reglas
    # pass out quick on $DEFAULT_IFACE inet to $ALLOW_IP
    # pass out quick proto tcp to $ALLOW_IP port { 8080 } keep state
    # pass in quick proto tcp from $ALLOW_IP port { 8080 } keep state
    cat <<EOF > "$ANCHOR_FILE"
block out all
block in all
pass out proto tcp to $ALLOW_IP port 8080
pass in quick inet from $ALLOW_IP
pass out proto tcp to 192.168.64.10 port 22
pass in quick inet from 192.168.64.10
pass out proto tcp to 10.0.0.2 port 22
pass in quick inet from 10.0.0.2
EOF

    # Asegurarse de que la anchor está referenciada en pf.conf
    if ! grep -q "anchor \"$ANCHOR_NAME\"" "$PF_CONF"; then
        echo "anchor \"$ANCHOR_NAME\"" >> "$PF_CONF"
        echo "load anchor \"$ANCHOR_NAME\" from \"$ANCHOR_FILE\"" >> "$PF_CONF"
    fi

   ls -l ~/ICM/.bin/fw4instructure.sh
   ~/ICM/.bin/fw4instructure.sh add
   echo SALIDA: $?

   echo "♻️ Recargando anchor '$ANCHOR_NAME'..."
   pfctl -a "$ANCHOR_NAME" -f "$ANCHOR_FILE"

   #echo "DESPUES:"
   #cat $ANCHOR_FILE
   #echo "======"

   #echo "XXXXXX"
   #cat /etc/pf.conf
   #echo "YYYYYY"

    # Verificar y aplicar configuración
    pfctl -nf "$PF_CONF" || { echo "Error en la configuración de pf."; exit 1; }

    pfctl -f "$PF_CONF"
    pfctl -e
    echo "Bloqueo activado. Solo $ALLOW_IP tiene salida."
}

function disable_blocking {
    echo "Desactivando bloqueo de pf..."

    pfctl -d

    # Opcional: limpiar la anchor
    rm -f "$ANCHOR_FILE"

    #~/ICM/.bin/fw4instructure.sh delete

    # Eliminar referencias en pf.conf si existen
    #exit
    #sed -i.bak "/anchor \"$ANCHOR_NAME\"/d" "$PF_CONF"
    #sed -i '' -e "/load anchor \"$ANCHOR_NAME\" from \"$ANCHOR_FILE\"/d" "$PF_CONF
    echo "Bloqueo desactivado. Acceso completo a internet restaurado."
}

# Ejecutar acción
case "$ACTION" in
    INICIO)
        enable_blocking
        ;;
    FIN)
        disable_blocking
        ;;
    *)
        echo "Acción no reconocida: $ACTION. Usa INICIO o FIN."
        exit 1
        ;;
esac
