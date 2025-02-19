#!/bin/bash
# Internet Connection Monitor - nelbren@nelbren.com @ 2025-02-19
setVariables() {
  timestampLast=$(date +'%Y-%m-%d %H:%M:%S')
  firstTime=1
  MY_NAME="Internet Connection Monitor"
  MY_VERSION=3.6
  REMOTE=0
  if [ -z "$1" ]; then
    TIME_INTERVAL=2
    IP=""
    ID=""
  else
    regex="^((25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])$"
    if [[ $1 =~ $regex ]]; then
      TIME_INTERVAL=2
      IP=$1
      ID=$2
    else
      if [ "$1" == "COMMIT" ]; then
        TIME_INTERVAL=0
      else
        TIME_INTERVAL=$1
      fi
      REMOTE=1
      ID=""
    fi
  fi
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
  checkUpdate
  checkSpace
  checkMD5
  checkAlias
  setBin
  setLogs $1
  trap logEnd INT
  getNameGit
  if [ "$1" == "COMMIT" ]; then
    takeCommitEvidence "$@"
    exit 0
  fi
  checkGit
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
takeCommitEvidence() {
  timestampNowGit=$(date +'%Y-%m-%d %H:%M:%S')
  now=$(echo $timestampNowGit | tr "[ ]" "[_]" | tr "[:]" "[\-]")
  DIR_GIT=${MY_DIR_GIT_LOG}/$now
  #echo $DIR_GIT
  if [ ! -d $DIR_GIT ]; then
    mkdir -p $DIR_GIT
  fi
  takeScreenshot $DIR_GIT
  git diff --cached > $DIR_GIT/git_diff_cached.txt
  exit 0
}
installPackages() {
  [ ! -x /usr/bin/netstat ] && sudo apt install net-tools
}
diffSeconds() {
  timePast=$1
  timeNow=$2
  # echo "timePast: '$timePast' timeNow: '$timeNow'"
  if [ $OS == "MACOS" ]; then
    timestampFormat="%Y-%m-%d %H:%M:%S"
    diffSecs=$(( $(date -j -f"$timestampFormat" "$timeNow" +%s) - $(date -j -f"$timestampFormat" "$timePast" +%s) ))
  else
    diffSecs=$(( $(date --date="$timeNow" +%s) - $(date --date="$timePast" +%s) ))
  fi
  echo $diffSecs
}
checkAlias() {
  aliasCmd="alias ICM='~/ICM/ICM.bash'"
  if ! echo $aliasCmd | grep -q ~/.profile; then
    echo $aliasCmd >> ~/.profile
  fi
}
checkGit() {
  if [ ! -r .git/config ]; then
    echo "Please run me from a git repository directory!"
    exit 1
  fi
  hook=.git/hooks/pre-commit
  if [ ! -x $hook ]; then
    echo "[ -x ~/ICM/ICM.bash ] && ~/ICM/ICM.bash COMMIT" > $hook
    chmod +x $hook
  fi
}
checkUpdate() {
  url=https://raw.githubusercontent.com/nelbren/ICM/refs/heads/main/ICM.bash
  data=$(curl -s $url --connect-timeout 2 -m 2 | egrep "MY_VERSION=\d+.\d+$")
  version=$(echo $data | cut -d"=" -f2)
  #echo $MY_VERSION $version 
  if [ -n "$version" ]; then
    if [ "$MY_VERSION" != "$version" ]; then
      printf "💻 ICM ${nR}v${MY_VERSION}${S} ${nW}!= 🌐 ICM ${nG}v${version}${S} -> ${nR}Please update, with: ${Iw}git pull${S}\n"
      exit 1
    fi
  fi
}
checkSpace() {
  MINIMUM=5 # G
  if [ $OS == "WINDOWS" ]; then
    avail=$(df -h / --output=avail | tail -1 | cut -d"G" -f1)
  else
    avail=$(df -h / | tail -1)
    avail=$(echo $avail | cut -d" " -f4 | cut -d"G" -f1)
  fi
  avail=$(echo $avail | cut -d"." -f1)
  if [ $avail -lt $MINIMUM ]; then
    echo "Please free up more available space (Minimum ${MINIMUM}G, Current ${avail}G)"
    exit 2
  fi
}
checkMD5() {
  if [ "$OS" == "MACOS" ]; then
    if ! echo "" | md5sum >/dev/null 2>&1; then
      echo "Plese install md5sum (brew install md5sha1sum)"
      exit 5
    fi
  fi
}
setBin() {
  MY_DIR_BIN=$HOME/ICM/.bin
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
  MY_DIR_BASE_LOG=$HOME/ICM/.logs
  #echo $MY_DIR_BASE_LOG
  if [ ! -d $MY_DIR_BASE_LOG ]; then
    mkdir -p $MY_DIR_BASE_LOG
  fi
  myTimestamp=$(date +'%Y-%m-%d')
  MY_DIR_DATE_LOG="${MY_DIR_BASE_LOG}/${myTimestamp}"
  if [ ! -d $MY_DIR_DATE_LOG ]; then
    mkdir -p $MY_DIR_DATE_LOG
  fi
  myPidStr=$(printf "%07d" $$)
  MY_DIR_PID_LOG="${MY_DIR_DATE_LOG}/${myPidStr}"
  if [ ! -d $MY_DIR_PID_LOG ]; then
    mkdir -p $MY_DIR_PID_LOG
  fi
  if [ "$1" != "COMMIT" ]; then
    MY_DIR_MVC_LOG="${MY_DIR_PID_LOG}/MVC"
    if [ ! -d $MY_DIR_MVC_LOG ]; then
      mkdir -p $MY_DIR_MVC_LOG
    fi
  fi
  MY_DIR_GIT_LOG="${MY_DIR_PID_LOG}/GIT"  
  if [ ! -d $MY_DIR_GIT_LOG ]; then
    mkdir -p $MY_DIR_GIT_LOG
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
    echo "Please set your name for git, using:"
    echo "git config --global user.name \"Your name\""
    exit 3
  fi
  name=$(echo $NAME | tr "[ ]" "[_]")
  email=$(git config user.email)
  if [ -z "$email" ]; then
    echo "Please set your email for git, using:"
    echo "git config --global user.email \"Your email\""
    exit 3
  fi
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
    interface=$(route -n get default 2>/dev/null | grep interface | cut -d":" -f2)
    data=$(ifconfig $interface | grep -w inet)
    ips=$(echo $data | cut -d" " -f2)
    data=$(ifconfig $interface | grep -w ether)
    macs=$(echo $data | cut -d" " -f2)
  elif [ "$OS" == "LINUX" ]; then
    interface=$(ip route | grep default | cut -d" " -f5)
    #echo $interface
    data=$(ip addr show $interface | grep "inet ")
    ips=$(echo $data | cut -d" " -f2)
    #echo $ips
    data=$(ip addr show $interface | grep "ether")
    macs=$(echo $data | cut -d" " -f2)
    #echo $macs
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
getGateway() {
  if [ "$OS" == "WINDOWS" ]; then
    data=$(route print -4 | grep -a " 0.0.0.0")
    #echo 0 $data >> SALIDA.txt
    gateway2=$(echo $data | cut -d" " -f3)
    #echo 1 $gateway2 >> SALIDA.txt
    if ! [[ $gateway2 =~ $regex ]]; then
      gateway2=$(echo $data | tr "[ ]" "[\n]" | tail -2 | head -1)
      #echo 2 $gateway2 >> SALIDA.txt
    fi
  elif [ "$OS" == "MACOS" ]; then
    gateway2=$(route -n get default | grep gateway | cut -d":" -f2)
  elif [ "$OS" == "LINUX" ]; then
    gateway2=$(ip route | grep default | cut -d" " -f3)
    #echo $gateway2 >> SALIDA.txt
  fi
  echo $gateway2 >  ~/.gateway.txt
  echo $gateway2 >>  ~/.gateways.txt
  echo $gateway2 # Retornar valor
}
setGateway() {
  [ -z "$IP" ] && return
  if [ "$OS" == "WINDOWS" ]; then
    # https://stackoverflow.com/questions/5944180/how-do-you-run-a-command-as-an-administrator-from-the-windows-command-line
    .bin/run-elevated.cmd $1 $2
    sleep 2 # Esperar a que se termine de aplicar el comando anterior
  elif [ "$OS" == "MACOS" ]; then
    # https://stackoverflow.com/questions/5560442/how-to-run-two-commands-with-sudo
    sudo -s -- <<EOF
route delete default
route add default $1
EOF
  elif [ "$OS" == "LINUX" ]; then
    sudo -s -- <<EOF
ip route del 0/0
ip route replace default via $1 $2
EOF
  fi
}
info() {
  etiqueta="$1"
  getNetwork
  echo $(timestamp $etiqueta)\|$myPidStr\|$(md5)\|${MY_VERSION}\|${HOSTNAME}\|${USERNAME}\|${name}\|${REMOTE}\|${TIME_INTERVAL}\|${ips}\|${macs}
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
  if [ "$OS" == "LINUX" ]; then
    ss -na > $MY_FILE_LOG_TEMP  
  else
    netstat -na > $MY_FILE_LOG_TEMP  
  fi
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
  elif [ "$OS" == "LINUX" ]; then
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
  if [ -z $1 ]; then
    EVIDENCE_FILE="$MY_DIR_EVIDENCE_LOG/$(date +'%Y-%m-%d_%H-%M-%S')_SCREENSHOT.png"
  else
    EVIDENCE_FILE="$1/$(date +'%Y-%m-%d_%H-%M-%S')_SCREENSHOT.png"
  fi
  if [ "$OS" == "WINDOWS" ]; then
    $MY_NCMD cmdwait 0 savescreenshot $EVIDENCE_FILE
  elif [ "$OS" == "MACOS" ]; then
    screencapture -x $EVIDENCE_FILE
  elif [ "$OS" == "LINUX" ]; then
    echo "$OS -> screenshot pendiente" > $MY_FILE_LOG_TEMP
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
  elif [ "$OS" == "LINUX" ]; then
    echo "$OS -> clipboard pendiente" > $MY_FILE_LOG_TEMP
  else
    echo "$OS -> clipboard undefined" > $MY_FILE_LOG_TEMP
  fi
  #printf "${nY}📋${S}"
  temp0=$(cat $MY_FILE_LOG_TEMP)
  temp1="${Iy} 📋 CLIPBOARD: ${EVIDENCE_FILE}${S}\n${nY}${temp0}\n"
  temp=$temp1
}
takeTaskList() {
  EVIDENCE_FILE="$MY_DIR_EVIDENCE_LOG/$(date +'%Y-%m-%d_%H-%M-%S')_TASKLIST.txt"
  if [ "$OS" == "WINDOWS" ]; then
    tasklist //FO CSV > $EVIDENCE_FILE
  elif [ "$OS" == "MACOS" ]; then
    ps -A > $EVIDENCE_FILE
  elif [ "$OS" == "LINUX" ]; then
    ps -ef > $EVIDENCE_FILE
  fi
}
takeExternalEvidence() {
  curl -s https://nelbren.com/$info3 --connect-timeout 2 -m 2 2>&1 | >/dev/null
}
playSound() {
  [ "$REMOTE" == "1" ] && return
  phrase="$NAME has access to the internet"
  if [ "$OS" == "WINDOWS" ]; then
    $MY_NCMD mediaplay 10000 $MY_SOUND
    $MY_NCMD speak text "$phrase"
  elif [ "$OS" == "MACOS" ]; then
    afplay $MY_SOUND
    say -v Whisper "$phrase"
  elif [ "$OS" == "LINUX" ]; then
    echo "FALTA SOUND"
    exit 1
  fi
}
evidence() {
  MY_DIR_EVIDENCE_LOG="${MY_DIR_PID_LOG}/evidence/"
  if [ ! -d $MY_DIR_EVIDENCE_LOG ]; then
    mkdir $MY_DIR_EVIDENCE_LOG
  fi

  temp=""
  #echo $MY_FILE_LOG_TEMP
  #if [ -r $MY_FILE_LOG_TEMP ]; then
    addCurlGoogle
    takeNetstat
    takePing
    takeIpInfo

    takeScreenshot
    takeClipboard
    takeTaskList
  #fi
}
checkGoogle() {
  internet=false
  echo > $MY_FILE_LOG_TEMP
  curl -o $MY_FILE_LOG_TEMP -s --connect-timeout 5 -m 2 http://google.com
  temp=$(cat $MY_FILE_LOG_TEMP)
  if [ -n "$temp" ]; then
    internet=true
  fi
}
checkGooglePing() {
  internet=false
  echo > $MY_FILE_LOG_TEMP
  if [ "$OS" == "WINDOWS" ]; then
    ping -n 1 google.com > $MY_FILE_LOG_TEMP
  elif [ "$OS" == "MACOS" ]; then
    ping -c 1 google.com > $MY_FILE_LOG_TEMP
  elif [ "$OS" == "LINUX" ]; then
    ping -c 1 google.com > $MY_FILE_LOG_TEMP
  else
    echo "$OS -> ping undefined" > $MY_FILE_LOG_TEMP
  fi
  if [ "$?" == "0" ]; then
    internet=true
  fi
}
checkGateway() {
  gateway2=""
  internet=true
  if [ "$OS" == "WINDOWS" ]; then
    #gateway2=$(powershell -Command "(Get-NetIPConfiguration).IPv4DefaultGateway.NextHop")
    gateway2=$(getGateway)
  elif [ "$OS" == "MACOS" -o "$OS" == "LINUX" ]; then
    gateway2=$(getGateway)
  fi
  if [ "$gateway2" == "$IP" ]; then
    internet=false
  fi
  #echo "gateway2 = $gateway2  == ip: $IP ==> internet: $internet"
}
checkInternet() {
  #if [ -n "$IP" -a -n "$ID" ]; then
  #  checkGateway
  #else
  #  checkGoogle
  #fi
  checkGoogle
  #checkGooglePing
  #echo $internet
  if $internet; then
    evidence $MY_FILE_LOG_TEMP
    info1=$(info "↓")
    printf "\n${Ir}${info1} EVIDENCIA:${S}\n\n$temp" >> $MY_FILE_LOG
    info2=$(info "→")
    #printf "${nW}${info2} ${nG}🌐✅${nW}→${nR}🎓❌\n" | tee -a $MY_FILE_LOG
    printf "${nW}${info2} ${nG}🌐✅${nW}→${nR}🎓❌\n" >> $MY_FILE_LOG
    printf "${nR}X"
    info3=$(echo PROG2/${info2} | tr "[ ]" "[_]")
    if [ -z "$IP" ]; then
      playSound
    fi
    #takeExternalEvidence
    #status="🌐"
    status="INTERNET"
  else
    #printf "${nW}$(info "→") ${nG}🌐❌${nW}→${nG}🎓✅\n" | tee -a $MY_FILE_LOG
    printf "${nW}$(info "→") ${nG}🌐❌${nW}→${nG}🎓✅\n" >> $MY_FILE_LOG
    printf "${nG}·"
    #status="✔️"
    #status=$(echo -e '\u2714')
    status="OK"
  fi
  if [ -n "$IP" -a -n "$ID" ]; then
    data="{\"id\" : \"$ID\", \"OS\" : \"$OS\", \"icmVersion\" : \"$MY_VERSION\", \"status\" : \"$status\"}"
    # echo $data
    curl -s -X POST -H "Content-Type: application/json; charset=utf-8" -d "$data" http://$IP:8080/update 2>&1 >/dev/null
    if [ "$?" == "0" ]; then
      color="${nG}"
    else
      color="${nR}"
    fi
    printf "${color}d"
  fi
}
archive() {
  TGZ="ICM.tgz"
  tar czf ~/$TGZ $MY_DIR_DATE_LOG
  ls -lh ~/$TGZ
}
disableInternet() {
  if [ -n "$IP" ]; then
    gateway=$(getGateway)
    #echo $gateway
    setGateway $IP INICIO
  fi
}
enableInternet() {
  if [ -n "$IP" ]; then
    setGateway $gateway FIN
  fi
}
updateMVC() {
  timestampNow=$(date +'%Y-%m-%d %H:%M:%S')
  ds=$(diffSeconds "$timestampLast" "$timestampNow")
  #updateAt=20 #15min * 60secs
  #updateAt=300 #15min * 60secs
  updateAt=900 #15min * 60secs
  #echo "'$ds' -gt '$updateAt'"
  printf "[$ds < $updateAt]"
  if [ "$ds" -gt "$updateAt" -o \
       "$firstTime" == "1" ]; then
    firstTime=0
    #echo $ds Is Time!!!!!
    now=$(echo $timestampNow | tr "[ ]" "[_]" | tr "[:]" "[\-]")
    DIR_MCV=${MY_DIR_MVC_LOG}/$now
    if [ ! -d $DIR_MCV ]; then
      mkdir -p $DIR_MCV
    fi
    error=0
    find . -type f -iname \*.cpp -o \
                   -iname \*.h* -o \
                   -iname \*.form -o \
                   -iname \*.java | \
    while read fileName; do
      #echo cp $fileName $DIR_MCV
      dirSrc=$(dirname $fileName)
      dirDst=${DIR_MCV}/${dirSrc}
      if [ "$dirSrc" != "." ]; then
        mkdir -p $dirDst
      fi
      #echo cp $fileName $dirDst
      cp $fileName $dirDst
      if [ "$?" != "0" ]; then
        error=1
      fi
    done
    if [ "$error" == "0" ]; then
      printf "${nG}β"
    else
      printf "${nR}β"
    fi
    #printf "($ds)"
    timestampLast=$timestampNow
  fi
}
setVariables $1 $2
logBegin
disableInternet
#while [ $TIEMPO_TRANSCURRIDO -lt $TIEMPO_TOTAL ]; do
while [ "$RUNNING" == "1" ]; do
  count
  checkInternet
  updateMVC
  sleep $TIME_INTERVAL
  #TIME_ELAPSED=$((TIME_ELAPSED + TIME_INTERVAL))
done
enableInternet
