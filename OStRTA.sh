#!/bin/bash

WakeOnLan() {
  while read tmp_string; do
    hostname=$(echo $tmp_string | awk '{print $1;}')
    addr=$(echo $tmp_string | awk '{print $2;}')
    PROBE_PING=`ping -s 1 -c 2 $hostname &> /dev/null; echo $?`
    if [ $PROBE_PING -eq 0 ];then
      echo -e "\e[1;93m[OStRTA]\e[1;97m\t$hostname is \e[1;92mUP\e[1;97m at $(date +%H:%M)\e[0;97m"
    elif [ $PROBE_PING -eq 1 ];then
      ether-wake -i enp3s0 $addr | echo -e "\e[1;93m[OStRTA]\e[1;97m\t$hostname is \e[1;91mDOWN\e[1;97m. WoL-packet sent at $(date +%H:%M)\e[0;97m"
    fi
  done < $addr_path

  sleep 30s | echo -e "\e[1;93m[OStRTA]\e[1;97m\tWait 30 seconds for all hosts to wake up...\e[0;97m"

  while read tmp_string; do
    hostname=$(echo $tmp_string | awk '{print $1;}')
    addr=$(echo $tmp_string | awk '{print $2;}')
    PROBE_PING=`ping -s 1 -c 2 $hostname &> /dev/null; echo $?`
    if [ $PROBE_PING -eq 0 ];then
      echo -e "\e[1;93m[OStRTA]\e[1;97m\t$hostname is \e[1;92mUP\e[1;97m at $(date +%H:%M)\e[0;97m"
    else
      echo -e "\e[1;93m[OStRTA]\e[1;97m\t$(date +%D\ %H:%M) : $hostname is still in \e[1;91mDOWN\e[1;97m state. Checkout connection and host's BIOS settings\e[0;97m"
      echo "$(date +%D\ %H:%M) : $hostname is still in DOWN state." >> ./log/$(date +%d%m%Y).log
    fi
  done < $addr_path
}

SendShutdown() {
  while read tmp_string; do
    hostname=$(echo $tmp_string | awk '{print $1;}')
    PROBE_PING=`ping -s 1 -c 2 $hostname &> /dev/null; echo $?`
    if [ $PROBE_PING -eq 1 ];then
      echo -e "\e[1;93m[OStRTA]\e[1;97m\t$hostname is \e[1;92mDOWN\e[1;97m at $(date +%H:%M)"
    elif [ $PROBE_PING -eq 0 ];then
      # Who is the last user? We'll know right back
      (ssh -n -o "BatchMode=yes" -o "ConnectTimeout=1" -o "StrictHostKeyChecking=no" $hostname shutdown 0)| echo -e "\e[1;93m[OStRTA]\e[1;97m\t$hostname is \e[1;91mUP\e[1;97m. Shutdown signal sent at $(date +%H:%M)\e[0;97m"
    fi
  done < $addr_path

  echo -e "\e[1;93m[OStRTA]\e[1;97m\tCheck if all hosts shutted down...\e[0;97m"

  while read tmp_string; do
    hostname=$(echo $tmp_string | awk '{print $1;}')
    PROBE_PING=`ping -s 1 -c 2 $hostname &> /dev/null; echo $?`
    if [ $PROBE_PING -eq 0 ];then
      echo -e "\e[1;93m[OStRTA]\e[1;97m\t$(date +%D\ %H:%M) : Host $hostname is still in \e[1;91mUP\e[1;97m state\e[0;97m"
      echo "$(date +%D\ %H:%M) : Shutdown incomplete" >> ./log/$(date +%d%m%Y).log
    else
      echo -e "\e[1;93m[OStRTA]\e[1;97m\t$hostname is \e[1;92mDOWN\e[1;97m at $(date +%H:%M)\e[0;97m"
    fi
  done < $addr_path
}

# Unstable. May be don't work correct
WhoIsOnline() {
  OnlineAmount=0
  TotalHosts=0
  OnlineHosts=()
  while read tmp_string; do
    TotalHosts=$((TotalHosts+1))
    hostname=$(echo $tmp_string | awk '{print $1;}')
    PROBE_PING=`ping -s 1 -c 2 $hostname &> /dev/null; echo $?`
    if [ $PROBE_PING -eq 0 ];then
      OnlineAmount=$((OnlineAmount+1))
      OnlineHosts+=($hostname)
      echo -ne "\e[1;93m[OStRTA]\e[1;97m\t$hostname is \e[1;92mUP\e[1;97m at $(date +%H:%M)\e[0;97m"
    elif [ $PROBE_PING -eq 1 ];then
      echo -ne "\e[1;93m[OStRTA]\e[1;97m\t$hostname is \e[1;91mDOWN\e[1;97m at $(date +%H:%M)\e[0;97m"
    fi
  done < $addr_path
  echo -e "\e[1;93m[OStRTA]\e[1;97m\t$OnlineAmount/$TotalHosts are \e[1;92mUP\e[1;97m at $(date +%H:%M)\e[0;97m"
  # Checking last user logged in. Coming soon
}

#---------------------
# Start of the script
#---------------------

if [ -z "$1" ]; then
  echo -e "\e[1;91mNothing to do. Use -h for help.\e[0;97m"
  exit 1
fi

addr_path="/root/manage-classes/OStRTA/conf/addr.dat"
ACTION=0

while [ -n "$1" ]; do
  case "$1" in
    -w) echo -e "\n\e[1;93m==>\e[1;97m Initialized hosts' wake up process...\e[0;97m"
    ACTION=1
    if [ -n "$2" ]; then
      if [ -f "conf/$2" ]; then
        addr_path="conf/$2"
      else
        echo -e "   \e[1;91mNo such configuration file: '$2'...\e[0;97m"
        exit 2
      fi
    fi
    shift;;

    -s)
    if [[ ACTION -eq 1 ]]; then
      echo -e "\n\e[1;91m==>\e[1;97m Do not use keys '-w' and '-s' at the same time.\e[0;97m"
      exit 3
    else
      echo -e "\n\e[1;93m==>\e[1;97m Initialized hosts' poweroff process...\e[0;97m"
      ACTION=2
    fi
    if [ -n "$2" ]; then
      if [ -f "conf/$2" ]; then
        addr_path="conf/$2"
      else
        echo -e "   \e[1;91mNo such configuration file: '$2'...\e[0;97m"
        exit 2
      fi
    fi
    shift;;

    -l) echo -e "\n\e[1;93m==>\e[1;97m Searching for active hosts...\e[0;97m"
    ACTION=3 ;;
    -h) echo -e "\n\e[1;97mUsage: ./$(basename "$0") <key> [CONF_FILE]\e[0;97m"
    echo -e "\e[1;97mExample: ./$(basename "$0") -w \e[0;97m"
    echo -e "\e[1;97mIf no file was passed, then script will engage all hosts from 'conf/addr.dat'\e[0;97m"
    echo -e "\n\e[1;97mAvailable keys:\e[0;97m"
    echo -e "\e[1;97m-w : Send Wake-On-LAN packet to the hosts\e[0;97m"
    echo -e "\e[1;97m-s : Send shutdown signal to the hosts\e[0;97m"
    echo -e "\e[1;97m-l : List all active hosts\e[0;97m"
    echo -e "\e[1;97m-h : Print this helpful message and quit\e[0;97m"
    echo -e "\n\e[1;97mNOTE: You are not able to use '-w' and '-p' keys at the same time. Script in Beta.\e[0;97m"
    exit 0 ;;
    *) echo -e "   \e[1;91mUnknow key '$1'...\e[0;97m"
    exit 4;;
  esac
  shift
done

# Command execution

if [[ ACTION -eq 1 ]]; then
  WakeOnLan
elif [[ ACTION -eq 2 ]]; then
  SendShutdown
elif [[ ACTION -eq 3 ]]; then
  WhoIsOnline
else
  echo -e "\e[1;91mOwO\e[0;97m\n"
  exit 5
fi

exit 0
