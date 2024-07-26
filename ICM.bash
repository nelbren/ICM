#!/bin/bash
# Internet Connection Monitor - nelbren@nelbren.com @ 2024-06-21
MY_NAME="Internet Connection Monitor"
MY_VERSION=1.7
INTERVALO=2
#TIEMPO_TOTAL=3600
NAME_LOG=ICM
ARCHIVO_LOG="${NAME_LOG}.log"
ARCHIVO_LOG_TEMP="/tmp/${NAME_LOG}_temp.log"
S="\e[0m";E="\e[K";n="$S\e[38;5";N="\e[9";e="\e[7";I="$e;49;9"
A=7m;R=1m;G=2m;Y=3m;nW="$N$A";nR="$N$R";nG="$N$G";nY="$N$Y"
Iw="$I$A";Ir="$I$R";Ig="$I$G";Iy="$I$Y"
timestamp() {
  evidencia=$1
  echo "${etiqueta}$(date +'%Y-%m-%d_%H-%M-%S')"
}
md5() {
  echo $(md5sum $0) | cut -d" " -f1
}
get_name() {
  file=.ICM.name.txt
  if [ -r $file ]; then
    name=$(cat $file)
  else
    name=""
    while [ -z "$name" ]; do
      echo -ne "${nW}NOMBRE COMPLETO: "
      read name;
    done
    name=$(echo $name | tr "[ ]" "[_]")
    echo $name > $file
  fi
}
airplane() {
  set +m
  shopt -s lastpipe
  interfaces=$(powershell -Command "Get-NetAdapter | Select MacAddress, Status | ft -HideTableHeaders")
  resumen=""
  #echo "($interfaces)"
  contador=0
  echo "$interfaces" | \
  while read linea; do
    contador=$((contador+1))
    macaddress=$(echo $linea | cut -d" " -f1)
    if [ -n "$macaddress" ]; then
      status=$(echo $linea | cut -d" " -f2)
      if [ "$status" == "Up" ]; then
        etiqueta="=UP"
        #color="${Iy}"
      else
        etiqueta="=DN"
        #color="${Ig}"
      fi
      if [ -n "$resumen" ]; then
        separador=","
      else
        separador=""
      fi
      resumen="${resumen}${separador}${macaddress}${etiqueta}"
    fi
  done
  echo "$resumen"
}
info() {
  etiqueta="$1"
  ip=$(ipconfig | grep -a IPv4 | cut -d":" -f2)
  if [ -z "$ip" ]; then
    ip="-"
  fi
  ip=$(echo $ip)
  ip=$(echo $ip | tr "[ ]" "[,]")
  #echo "($ip)"
  macs=$(airplane)
  #macs="01=UP"

  echo $(timestamp $etiqueta)\|$$\|$(md5)\|${MY_VERSION}\|${HOSTNAME}\|${USERNAME}\|${name}\|${ip}\|${macs}
}
evidencia() {
  temp=""
  if [ -r $ARCHIVO_LOG_TEMP ]; then
    temp0=$(cat $ARCHIVO_LOG_TEMP)
    temp1="${Iy}1) curl http://google.com:${S}\n${nY}${temp0}\n"
    temp=$temp1
    netstat -na > $ARCHIVO_LOG_TEMP
    temp0=$(cat $ARCHIVO_LOG_TEMP)
    temp1="\n${Iy}2) netstat -na:${S}\n${nY}${temp0}\n"
    temp="${temp}${temp1}"
    ping -n 1 google.com > $ARCHIVO_LOG_TEMP
    temp0=$(cat $ARCHIVO_LOG_TEMP)
    temp1="\n${Iy}3) ping -n 1 google.com${S}\n${nY}${temp0}\n"
    temp="${temp}${temp1}"
    curl -s https://ipinfo.io/json > $ARCHIVO_LOG_TEMP
    temp0=$(cat $ARCHIVO_LOG_TEMP)
    temp1="\n${Iy}4) curl https://ipinfo.io/json${S}\n${nY}${temp0}\n"
    temp="${temp}${temp1}"
  else
    temp=""
  fi
}
check_internet() {
  internet=false
  echo > $ARCHIVO_LOG_TEMP
  curl -o $ARCHIVO_LOG_TEMP -s --connect-timeout 2 -m 2 http://google.com
  temp=$(cat $ARCHIVO_LOG_TEMP)
  if [ -n "$temp" ]; then
    internet=true
  fi
  if $internet; then
    evidencia $ARCHIVO_LOG_TEMP
    info1=$(info "↓")
    echo -e "\n${Ir}${info1} EVIDENCIA:${S}\n\n$temp" >> $ARCHIVO_LOG
    info2=$(info "→")
    echo -e "${nW}${info2} ${nG}🌐✅${nW}→${nR}🎓❌" | tee -a $ARCHIVO_LOG
    info3=$(echo PROG2/${info2} | tr "[ ]" "[_]")
    #echo "($info3)"
    curl -s https://nelbren.com/$info3 --connect-timeout 2 -m 2 2>&1 | >/dev/null
  else
    echo -e "${nW}$(info "→") ${nG}🌐❌${nW}→${nG}🎓✅" | tee -a $ARCHIVO_LOG
  fi
}
get_name
TIEMPO_TRANSCURRIDO=0
echo -e "${Iw}$(info "•")${S}${nG} 🔜${MY_NAME} v${MY_VERSION} Started✅" | tee -a $ARCHIVO_LOG
#while [ $TIEMPO_TRANSCURRIDO -lt $TIEMPO_TOTAL ]; do
while [ true ]; do
  check_internet
  sleep $INTERVALO
  TIEMPO_TRANSCURRIDO=$((TIEMPO_TRANSCURRIDO + INTERVALO))
done
echo -e "${Iw}$(info "•")${S}${nG} 🔚${MY_NAME} v${MY_VERSION} Completed❎" | tee -a $ARCHIVO_LOG

