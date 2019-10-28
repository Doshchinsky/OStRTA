#!/bin/bash

WTFUS() {
  TST_PING=`ping -s 1 -c 2 Hyperion > /dev/null; echo $?`
  if [ $TST_PING -eq 0 ];then
    echo -e "Hyperion is UP as on $(date)"
  elif [ $TST_PING -eq 1 ];then
    ether-wake ac:e2:d3:72:d9:6f | echo "Hyperion is not turned on. WOL packet sent at $(date +%H:%M)"
    sleep 3m | echo "Waiting 3 Minutes"
    PING=`ping -s 1 -c 4 Hyperion > /dev/null; echo $?`
    if [ $PING -eq 0 ];then
      echo "Hyperion is UP as on $(date +%H:%M)"
    else
      echo "$(date +%D\ %H:%M) : Host is still in DOWN state"
      echo "$(date +%D\ %H:%M) : Host is still in DOWN state" >> ./log/$(date +%d%m%Y).log
    fi
  fi
}

STFD() {
  TST_PING=`ping -s 1 -c 2 Hyperion > /dev/null; echo $?`
  if [ $TST_PING -eq 1 ];then
    echo -e "Hyperion is DOWN as on $(date)"
  elif [ $TST_PING -eq 0 ];then
    (ssh -n -o "BatchMode=yes" -o "ConnectTimeout=1" -o "StrictHostKeyChecking=no" Hyperion `touch TEST.TEST`)| echo "Hyperion is UP. WOL packet sent at $(date +%H:%M)"
    # sleep 3m | echo "Waiting 3 Minutes"
    PING=`ping -s 1 -c 4 Hyperion > /dev/null; echo $?`
    if [ $PING -eq 0 ];then
      echo "$(date +%D\ %H:%M) : Host is still in UP state"
      echo "$(date +%D\ %H:%M) : Shutdown incomplete" >> ./log/$(date +%d%m%Y).log
    else
      echo "Hyperion is DOWN as on $(date +%H:%M)"
    fi
  fi
}

readonly me=$(basename "$0")
readonly hosts_list="^.wp[0-9][0-9]"	# regular expression for grep
ENABLE_ALL=0
WAKE=0
SHUT=0

while [ -n "$1" ]; do
  case "$1" in
    -a) ENABLE_ALL=1 ;;
    -w) echo -e "\n\e[1;93m==>\e[1;97m Initialized hosts wake up process...\e[0;97m"
    WAKE=1 ;;
    -s) echo -e "\n\e[1;93m==>\e[1;97m Initialized hosts shutdown process...\e[0;97m"
    SHUT=1 ;;
    -h) echo "Usage: $me <key> <value>"
    echo "Example: $me -a -w "
    echo "Available keys:"
    echo "-a : Execute command on all hosts by default pattern"
    echo "-w : Send Wake-On-LAN packet to the selected hosts"
    echo "-s : Send shutdown signal to the selected hosts"
    echo "-h : Print this helpful message and quit"
    echo "About: This script executes the command on all machines in the classes. Hostnames are taken directly from the DNS zone by a pattern."
    exit 0 ;;
    *) echo -e "   \e[1;91mUnknow key '$1'...\e[0;97m\n"
  esac
  shift
done

# Command execution
if [[ WAKE -eq 1 ]]; then
  WTFUS
fi
if [[ SHUT -eq 1 ]]; then
  STFD
fi

exit 0
