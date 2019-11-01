#!/bin/bash

#----------------------
# Wake The F Up Samurai
#----------------------

WTFUS() {
  for addr in $2;do
    TST_PING=`ping -s 1 -c 2 Hyperion > /dev/null; echo $?`
    if [ $TST_PING -eq 0 ];then
      echo -e "\e[1;93m[OStRTA]\e[1;97m\tHyperion is UP as on $(date)\e[0;97m"
      exit 0
    elif [ $TST_PING -eq 1 ];then
      ether-wake -i enp3s0 $addr | echo -e "\e[1;93m[OStRTA]\e[1;97m\tHyperion is not turned on. WoL-packet sent at $(date +%H:%M)\e[0;97m"
      sleep 3m | echo -e "\e[1;93m[OStRTA]\e[1;97m\tWaiting 3 Minutes...\e[0;97m"
      PING=`ping -s 1 -c 4 Hyperion > /dev/null; echo $?`
      if [ $PING -eq 0 ];then
        echo -e "\e[1;93m[OStRTA]\e[1;97m\tHyperion is UP as on $(date +%H:%M)\e[0;97m"
      else
        echo -e "\e[1;93m[OStRTA]\e[1;97m\t$(date +%D\ %H:%M) : Host is still in DOWN state\e[0;97m"
        echo "$(date +%D\ %H:%M) : Host is still in DOWN state" >> ./log/$(date +%d%m%Y).log
      fi
    fi
  done
}

#---------------------
# Shut The F Down
#---------------------

STFD() {
  TST_PING=`ping -s 1 -c 2 Hyperion > /dev/null; echo $?`
  if [ $TST_PING -eq 1 ];then
    echo -e "\e[1;93m[OStRTA]\e[1;97m\tHyperion is DOWN as on $(date)"
  elif [ $TST_PING -eq 0 ];then
    (ssh -n -o "BatchMode=yes" -o "ConnectTimeout=1" -o "StrictHostKeyChecking=no" Hyperion `shutdown 0`)| echo -e "\e[1;93m[OStRTA]\e[1;97m\tHyperion is UP. Poweroff signal sent at $(date +%H:%M)\e[0;97m"
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

#---------------------
# Start of the script
#---------------------

readonly me=$(basename "$0")
readonly template="^.wp[0-9][0-9]"	# regular expression for grep
readonly mac_path="./conf/mac.dat"
readonly ip_path="./conf/ip.dat"
ACTION=0

while [ -n "$1" ]; do
  case "$1" in
    -w) echo -e "\n\e[1;93m==>\e[1;97m Initialized hosts' wake up process...\e[0;97m"
    ACTION=1 ;;
    -p)
    if [[ ACTION -eq 1 ]]; then
      echo -e "\n\e[1;91m==>\e[1;97m Do not use keys '-w' and '-p' at the same time.\e[0;97m"
      exit -2
    else
      echo -e "\n\e[1;93m==>\e[1;97m Initialized hosts' poweroff process...\e[0;97m"
      ACTION=2
    fi;;
    -l) echo -e "\n\e[1;93m==>\e[1;97m Searching for active hosts...\e[0;97m"
    ACTION=3 ;;
    -h) echo -e "\n\e[1;97mUsage: $me <keys> <value>\e[0;97m"
    echo -e "\e[1;97mExample: $me -a -w \e[0;97m"
    echo -e "\n\e[1;97mAvailable keys:\e[0;97m"
    echo -e "\e[1;97m-w : Send Wake-On-LAN packet to the hosts\e[0;97m"
    echo -e "\e[1;97m-p : Send shutdown signal to the hosts\e[0;97m"
    echo -e "\e[1;97m-l : List all active hosts\e[0;97m"
    echo -e "\e[1;97m-h : Print this helpful message and quit\e[0;97m"
    echo -e "\n\e[1;97mNOTE: Script in Beta.\e[0;97m"
    exit 0 ;;
    *) echo -e "   \e[1;91mUnknow key '$1'...\e[0;97m"
    exit -1;;
  esac
  shift
done

# Command execution
if [[ ACTION -eq 0 ]]; then
  echo -e "\e[1;91mNothing to do.\e[0;97m"
elif [[ ACTION -eq 1 ]]; then
  echo "WTFUS"
  #addr_list=$(cat $mac_path | awk '{print $2;}')
  #WTFUS
elif [[ ACTION -eq 2 ]]; then
  echo "STFD"
  #ip_list=$(cat $ip_path | awk '{print $2;}')
  #STFD $host_list $addr_list
elif [[ ACTION -eq 3 ]]; then
  echo "Listing"
else
  echo -e "\e[1;91mOwO\e[0;97m\n"
  exit -2
fi

exit 0
