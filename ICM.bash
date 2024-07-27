#!/bin/bash
# Internet Connection Monitor - nelbren@nelbren.com @ 2024-07-27
setVariables() {
  MY_NAME="Internet Connection Monitor"
  MY_VERSION=2.0
  TIME_INTERVAL=2
  #TIME_TOTAL=3600
  TIME_ELAPSED=0
  S="\e[0m";E="\e[K";n="$S\e[38;5";N="\e[9";e="\e[7";I="$e;49;9"
  A=7m;R=1m;G=2m;Y=3m;nW="$N$A";nR="$N$R";nG="$N$G";nY="$N$Y"
  Iw="$I$A";Ir="$I$R";Ig="$I$G";Iy="$I$Y"
  # ((X=(2**63)-1)); echo $X
  MY_COUNT_MAX=9223372036854775807
  MY_COUNT=0
  count
  RUNNING=1
  getOSType
  checkSpace
  setBin
  setLogs
  trap logEnd INT
  getNameGit
}
getOSType() {
  OS=""
  case "$OSTYPE" in
    linux*)
      OS=LINUX;;
    darwin*)
      USERNAME=$USER
      OS=MACOS;;
      #arch=$(uname -m)
      #if [ "$arch" = "x86_64" ]; then
      #  echo "Sistema operativo: macOS (Intel)"
      #elif [ "$arch" = "arm64" ]; then
      #  echo "Sistema operativo: macOS (Apple Silicon)"
      #else
      #  echo "Sistema operativo: macOS (arquitectura desconocida)"
      #fi
    msys*)
      OS=WINDOWS;;
    cygwin*)
      OS=WINDOWS;;
    *)
      echo "Sistema operativo desconocido: $OSTYPE"
      exit 1;;
  esac
}
checkSpace() {
  MINIMUM=5 # G
  if [ $OS == "WINDOWS" ]; then
    avail=$(df -h / --output=avail | tail -1 | cut -d"G" -f1)
  else
    avail=$(df -h / | tail -1)
    avail=$(echo $avail | cut -d" " -f4 | cut -d"G" -f1)
  fi
  avail=$(echo $avail)
  if [ $avail -lt $MINIMUM ]; then
    echo "Please free up more available space (Minimum ${MINIMUM}G, Current ${avail}G)"
    exit 2
  fi
}
setBin() {
  MY_DIR_BIN=.bin
  MY_URL=https://nelbren.com/unitec/
  if [ ! -d $MY_DIR_BIN ]; then
    mkdir $MY_DIR_BIN
  fi
  if [ "$OS" == "WINDOWS" ]; then
    NCMD=nircmdc.exe
    MY_NCMD=$MY_DIR_BIN/$NCMD
    if [ ! -r $MY_NCMD ]; then
      curl -s $MY_URL/$NCMD -o $MY_NCMD
      #ls -lh $MY_NCMD
    fi
    #NHV=BrowsingHistoryView.exe
    #MY_BHV=$MY_DIR_BIN/$NHV
    #if [ ! -r $MY_BHV ]; then
    #  curl -s $MY_URL/$NHV -o $MY_BHV
    #  #ls -lh $MY_BHV
    #fi
  fi
  SOUND=dial-up-modem-02.mp3
  MY_SOUND=$MY_DIR_BIN/$SOUND
  if [ ! -r $MY_SOUND ]; then
    curl -s $MY_URL/$SOUND -o $MY_SOUND
    #ls -lh $MY_SOUND
  fi
  if [ ! -r $MY_SOUND ]; then
    echo "I can't connect to the Internet to download the required files!"
    exit 4
  fi
}
setLogs() {
  MY_DIR_BASE_LOG=.logs
  if [ ! -d $MY_DIR_BASE_LOG ]; then
    mkdir $MY_DIR_BASE_LOG
  fi
  myTimestamp=$(date +'%Y-%m-%d')
  MY_DIR_DATE_LOG="${MY_DIR_BASE_LOG}/${myTimestamp}"
  if [ ! -d $MY_DIR_DATE_LOG ]; then
    mkdir $MY_DIR_DATE_LOG
  fi
  myPidStr=$(printf "%07d" $$)
  MY_DIR_PID_LOG="${MY_DIR_DATE_LOG}/${myPidStr}"
  if [ ! -d $MY_DIR_PID_LOG ]; then
    mkdir $MY_DIR_PID_LOG
  fi
  MY_NAME_LOG=ICM
  MY_FILE_LOG="${MY_DIR_PID_LOG}/${MY_NAME_LOG}.log"
  MY_FILE_LOG_TEMP="/tmp/${MY_NAME_LOG}_temp.log"
}
count() {
  if [ $MY_COUNT -lt $MY_COUNT_MAX ]; then
    MY_COUNT=$((MY_COUNT + 1))
  else
    MY_COUNT=0
  fi
  myCountStr=$(printf "%019d" $MY_COUNT)
}
timestamp() {
  label=$1
  echo "${label}$(date +'%Y-%m-%d_%H-%M-%S')|${myCountStr}"
}
md5() {
  echo $(md5sum $0) | cut -d" " -f1
}
getName() {
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
getNameGit() {
  NAME=$(git config user.name)
  if [ -z "$NAME" ]; then
    echo "Configure the git config!"
    exit 3
  fi
  name=$(echo $NAME | tr "[ ]" "[_]")
  email=$(git config user.email)
  name="${name}($email)"
}
getMACWindows() {
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
logBegin() {
  #echo -e "${Iw}$(info "•")${S}${nG} 🔜${MY_NAME} v${MY_VERSION} Started✅" | tee -a $MY_FILE_LOG
  printf "${Iw}$(info "•")${S}${nG} 🔜${MY_NAME} v${MY_VERSION} Started✅\n" | tee -a $MY_FILE_LOG
}
logEnd() {
  RUNNING=0
  count
  #echo -e "${Iw}$(info "•")${S}${nG} 🔚${MY_NAME} v${MY_VERSION} Completed❎" | tee -a $MY_FILE_LOG
  printf "${Iw}$(info "•")${S}${nG} 🔚${MY_NAME} v${MY_VERSION} Completed❎\n" | tee -a $MY_FILE_LOG
  archive
}
getNetwork() {
  if [ "$OS" == "WINDOWS" ]; then
    ips=$(ipconfig | grep -a IPv4 | cut -d":" -f2)
    data=$(ipconfig.exe //all | grep -aE "Physical|sica" | cut -d":" -f2)
    macs=$(echo $data)
    #macs=$(getMACWindows)
  elif [ "$OS" == "MACOS" ]; then
    interface=$(route -n get default | grep interface | cut -d":" -f2)
    data=$(ifconfig $interface | grep -w inet)
    ips=$(echo $data | cut -d" " -f2)
    data=$(ifconfig $interface | grep -w ether)
    macs=$(echo $data | cut -d" " -f2)
  fi
  if [ -z "$ips" ]; then
    ips="-"
  fi
  ips=$(echo $ips)
  ips=$(echo $ips | tr "[ ]" "[,]")
  macs=$(echo $macs)
  macs=$(echo $macs | tr "[ ]" "[,]")
  #echo "IP: $ip MAC: $macs"
}
info() {
  etiqueta="$1"
  getNetwork
  echo $(timestamp $etiqueta)\|$myPidStr\|$(md5)\|${MY_VERSION}\|${HOSTNAME}\|${USERNAME}\|${name}\|${ips}\|${macs}
}
addCurlGoogle() {
  EVIDENCE_FILE="$MY_DIR_EVIDENCE_LOG/$(date +'%Y-%m-%d_%H-%M-%S')_GOOGLE.txt"
  temp0=$(cat $MY_FILE_LOG_TEMP)
  temp1="${Iy} curl http://google.com:${S}\n${nY}${temp0}\n"
  temp=$temp1
  cp $MY_FILE_LOG_TEMP $EVIDENCE_FILE
}
takeNetstat() {
  EVIDENCE_FILE="$MY_DIR_EVIDENCE_LOG/$(date +'%Y-%m-%d_%H-%M-%S')_NETSTAT.txt"
  netstat -na > $MY_FILE_LOG_TEMP  
  temp0=$(cat $MY_FILE_LOG_TEMP)
  temp1="\n${Iy} netstat -na:${S}\n${nY}${temp0}\n"
  temp="${temp}${temp1}"
  cp $MY_FILE_LOG_TEMP $EVIDENCE_FILE
}
takePing() {
  EVIDENCE_FILE="$MY_DIR_EVIDENCE_LOG/$(date +'%Y-%m-%d_%H-%M-%S')_PING.txt"
  if [ "$OS" == "WINDOWS" ]; then
    ping -n 1 google.com > $MY_FILE_LOG_TEMP
  elif [ "$OS" == "MACOS" ]; then
    ping -c 1 google.com > $MY_FILE_LOG_TEMP
  else
    echo "$OS -> ping undefined" > $MY_FILE_LOG_TEMP
  fi
  temp0=$(cat $MY_FILE_LOG_TEMP)
  temp1="\n${Iy} ping -n 1 google.com${S}\n${nY}${temp0}\n"
  temp="${temp}${temp1}"
  cp $MY_FILE_LOG_TEMP $EVIDENCE_FILE
}
takeIpInfo() {
  EVIDENCE_FILE="$MY_DIR_EVIDENCE_LOG/$(date +'%Y-%m-%d_%H-%M-%S')_IPINFO.txt"
  curl -s https://ipinfo.io/json > $MY_FILE_LOG_TEMP
  temp0=$(cat $MY_FILE_LOG_TEMP)
  temp1="\n${Iy} curl https://ipinfo.io/json${S}\n${nY}${temp0}\n"
  temp="${temp}${temp1}"
  cp $MY_FILE_LOG_TEMP $EVIDENCE_FILE
}
takeScreenshot() {  
  EVIDENCE_FILE="$MY_DIR_EVIDENCE_LOG/$(date +'%Y-%m-%d_%H-%M-%S')_SCREENSHOT.png"
  if [ "$OS" == "WINDOWS" ]; then
    $MY_NCMD cmdwait 0 savescreenshot $EVIDENCE_FILE
  elif [ "$OS" == "MACOS" ]; then
    screencapture -x $EVIDENCE_FILE
  else
    echo "$OS -> screenshot undefined" > $MY_FILE_LOG_TEMP
  fi
  #printf "${nY}📷${S}"
  temp0=$(cat $MY_FILE_LOG_TEMP)
  temp1="${Iy} 📷 SCREENSHOT: ${EVIDENCE_FILE}${S}\n${nY}${temp0}\n"
  temp=$temp1
}
takeClipboard() {
  EVIDENCE_FILE="$MY_DIR_EVIDENCE_LOG/$(date +'%Y-%m-%d_%H-%M-%S')_CLIPBOARD.txt"
  if [ "$OS" == "WINDOWS" ]; then
    $MY_NCMD clipboard addfile $EVIDENCE_FILE
  elif [ "$OS" == "MACOS" ]; then
    pbpaste > $EVIDENCE_FILE
  else
    echo "$OS -> clipboard undefined" > $MY_FILE_LOG_TEMP
  fi
  #printf "${nY}📋${S}"
  temp0=$(cat $MY_FILE_LOG_TEMP)
  temp1="${Iy} 📋 CLIPBOARD: ${EVIDENCE_FILE}${S}\n${nY}${temp0}\n"
  temp=$temp1
}
takeExternalEvidence() {
  curl -s https://nelbren.com/$info3 --connect-timeout 2 -m 2 2>&1 | >/dev/null
}
playSound() {
  phrase="$NAME has access to the internet"
  if [ "$OS" == "WINDOWS" ]; then
    $MY_NCMD mediaplay 10000 $MY_SOUND
    $MY_NCMD speak text "$phrase"
  elif [ "$OS" == "MACOS" ]; then
    afplay $MY_SOUND
    say -v Whisper "$phrase"
  fi
 }
evidence() {
  MY_DIR_EVIDENCE_LOG="${MY_DIR_PID_LOG}/evidence/"
  if [ ! -d $MY_DIR_EVIDENCE_LOG ]; then
    mkdir $MY_DIR_EVIDENCE_LOG
  fi

  temp=""
  if [ -r $MY_FILE_LOG_TEMP ]; then
    addCurlGoogle
    takeNetstat
    takePing
    takeIpInfo

    takeScreenshot
    takeClipboard
  fi
}
checkInternet() {
  internet=false
  echo > $MY_FILE_LOG_TEMP
  curl -o $MY_FILE_LOG_TEMP -s --connect-timeout 2 -m 2 http://google.com
  temp=$(cat $MY_FILE_LOG_TEMP)
  if [ -n "$temp" ]; then
    internet=true
  fi
  if $internet; then
    evidence $MY_FILE_LOG_TEMP
    info1=$(info "↓")
    printf "\n${Ir}${info1} EVIDENCIA:${S}\n\n$temp" >> $MY_FILE_LOG
    info2=$(info "→")
    printf "${nW}${info2} ${nG}🌐✅${nW}→${nR}🎓❌\n" | tee -a $MY_FILE_LOG
    info3=$(echo PROG2/${info2} | tr "[ ]" "[_]")
    playSound
    #takeExternalEvidence
  else
    printf "${nW}$(info "→") ${nG}🌐❌${nW}→${nG}🎓✅\n" | tee -a $MY_FILE_LOG
  fi
}
archive() {
  TGZ="ICM.tgz"
  tar czf ~/$TGZ $MY_DIR_DATE_LOG
  ls -lh ~/$TGZ
}
setVariables
logBegin
#while [ $TIEMPO_TRANSCURRIDO -lt $TIEMPO_TOTAL ]; do
while [ "$RUNNING" == "1" ]; do
  count
  checkInternet
  sleep $TIME_INTERVAL
  #TIME_ELAPSED=$((TIME_ELAPSED + TIME_INTERVAL))
done
