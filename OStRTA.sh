#!/bin/bash

# Get The List Of Hosts
GTLOH() {
  for line in $hosts_list; do
    wp_list=$(cat $data_path | grep 'wp' | awk '{print $3;}')
    for wp in $wp_list; do
      echo $wp
    done
  done
}

# Wake The F Up Samurai
WTFUS() {
  TST_PING=`ping -s 1 -c 2 Hyperion > /dev/null; echo $?`
  if [ $TST_PING -eq 0 ];then
    echo -e "\e[1;93m[OStRTA]\e[1;97m\tHyperion is UP as on $(date)\e[0;97m"
    exit 0
  elif [ $TST_PING -eq 1 ];then
    ether-wake ac:e2:d3:72:d9:6f | echo -e "\e[1;93m[OStRTA]\e[1;97m\tHyperion is not turned on. WoL-packet sent at $(date +%H:%M)\e[0;97m"
    sleep 3m | echo -e "\e[1;93m[OStRTA]\e[1;97m\tWaiting 3 Minutes...\e[0;97m"
    PING=`ping -s 1 -c 4 Hyperion > /dev/null; echo $?`
    if [ $PING -eq 0 ];then
      echo -e "\e[1;93m[OStRTA]\e[1;97m\tHyperion is UP as on $(date +%H:%M)\e[0;97m"
    else
      echo -e "\e[1;93m[OStRTA]\e[1;97m\t$(date +%D\ %H:%M) : Host is still in DOWN state\e[0;97m"
      echo "$(date +%D\ %H:%M) : Host is still in DOWN state" >> ./log/$(date +%d%m%Y).log
    fi
  fi
}

# Shut The F Down
STFD() {
  TST_PING=`ping -s 1 -c 2 Hyperion > /dev/null; echo $?`
  if [ $TST_PING -eq 1 ];then
    echo -e "\e[1;93m[OStRTA]\e[1;97m\tHyperion is DOWN as on $(date)"
  elif [ $TST_PING -eq 0 ];then
    (ssh -n -o "BatchMode=yes" -o "ConnectTimeout=1" -o "StrictHostKeyChecking=no" Hyperion `poweroff -f --no-wall`)| echo -e "\e[1;93m[OStRTA]\e[1;97m\tHyperion is UP. Poweroff signal sent at $(date +%H:%M)\e[0;97m"
    sleep 2m | echo "Waiting 2 Minutes"
    PING=`ping -s 1 -c 4 Hyperion > /dev/null; echo $?`
    if [ $PING -eq 0 ];then
      echo -e "\e[1;93m[OStRTA]\e[1;97m\t$(date +%D\ %H:%M) : Host is still in UP state"
      echo "$(date +%D\ %H:%M) : Shutdown incomplete" >> ./log/$(date +%d%m%Y).log
    else
      echo -e "\e[1;93m[OStRTA]\e[1;97m\tHyperion is DOWN as on $(date +%H:%M)\e[0;97m"
    fi
  fi
}

readonly me=$(basename "$0")
readonly hosts_list="^.wp[0-9][0-9]"	# regular expression for grep
# readonly data_path="/etc/dhcp/dhcpd.conf"
readonly data_path="./dhcpd.conf"
ENABLE_ALL=0
SELECTED=0
ADDRESS=0
WAKE=0
SHUT=0

while [ -n "$1" ]; do
  case "$1" in
    -a) ENABLE_ALL=1 ;;
    -s) SELECTED=1
    ADDRESS=$2
    shift ;;
    -w) echo -e "\n\e[1;93m==>\e[1;97m Initialized hosts wake up process...\e[0;97m"
    WAKE=1 ;;
    -p) echo -e "\n\e[1;93m==>\e[1;97m Initialized hosts poweroff process...\e[0;97m"
    SHUT=1 ;;
    -h) echo "Usage: $me <key> <value>"
    echo "Example: $me -a -w "
    echo "Available keys:"
    echo "-a : Execute command on ALL hosts by default pattern"
    echo "-s : Execute command on SELECTED host"
    echo "-w : Send Wake-On-LAN packet to the selected hosts"
    echo "-p : Send shutdown signal to the selected hosts"
    echo "-h : Print this helpful message and quit"
    echo "About: This script executes the command on all machines in the classes. Hostnames are taken directly from the DNS zone by a pattern."
    exit 0 ;;
    *) echo -e "   \e[1;91mUnknow key '$1'...\e[0;97m\n"
  esac
  shift
done

# Command execution
if [[ ENABLE_ALL -eq 1 ]]; then
  GTLOH
elif [[ SELECTED -eq 1 ]];then
  echo $ADDRESS
elif [[ SELECTED -eq 0 ]];then
  echo "Nothing to do :("
  exit -1
fi

if [[ WAKE -eq 1 ]]; then
  WTFUS
fi

if [[ SHUT -eq 1 ]]; then
  STFD
fi

exit 0
