#!/bin/bash
#Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

trap ctrl_c INT
function ctrl_c(){
  # Salimos del programa con codigo no exitoso
  echo -e "${redColour}[*] Saliendo...${endColour}"
  exit 1
}

if [ $(id -u) = "0" ]; then

  function dependencies(){
    #Dependencias básicas
    dep=(wpa_supplicant dhclient iwlist)
    for item in "${dep[@]}"; do
      # Comprueba las dependencias
      test -f /usr/sbin/$item
      if [[ $(echo $?) != "0" ]]; then
        echo -e "${redColour}$item${endColour} does not exist in the system or is unrechable"
        exit 1
      fi
    done
  }

  function HelpPanel() {
    # Panel de ayuda
    echo "==== Tool for scan and connect with an Access Point ===="
    echo -e "\t\t${turquoiseColour}wifiConnect <INTERFACE>${endColour} to do a simple scan"
    echo -e "\t\t${turquoiseColour}wifiConnect <interface> <ESSID> <PASSWORD>${endColour} to make the connection"
  }

  function checkIface(){
    #Comprueba si existe la interfaz
    iface=$1
    if [ ! -d /sys/class/net/$iface ]; then
      echo -e "${yellowColour}[!] ${redColour}ERROR: ${yellowColour}$1 does not exist in the system or is unrechable${endColour}"
      exit 1
    else
      return 0
    fi
  }
  function scan() {
    if checkIface "$1" ; then
      iwlist $1 scan | grep -i essid | cut -d ':' -f2 | sed 's/"//g'
    fi
}
  function connect() {
    checkIface $1
    wpa_passphrase $2 $3 > /tmp/connectWifi.conf
    echo -e "${purpleColour}[!] Creating a temporal file: /tmp/connectWifi.conf"
    wpa_supplicant -B -i $1 -c /tmp/connectWifi.conf >/dev/null
    rm -rf /tmp/connectWifi.conf
    echo -e "${yellowColour}[...] Connecting...${endColour}"
    timeout 45 dhclient -v $1 2>/dev/null
    if [ $? == '124'  ];then
      echo -e "${redColour}[!] Somethig has gone wrong with the dhcp request${endColour}"
    else
      echo -e "${greenColour}[*] Connected${endColour}"
      echo -e "Youtr new IP is: $(ifconfig $1 | grep inet | sed 's/  */ /g' | cut -d' ' -f3)"
    fi



  }
  case $# in
    1)
      if [[ $1 == "-h" || $1 == "--help" ]]; then
        HelpPanel
        exit 0
      fi
      scan $1
    ;;
    3)
      connect $1 $2 $3
      ;;
    *)
      HelpPanel;;
  esac
else
  echo -e "${redColour}[!] Run as root${endColour}"
fi
