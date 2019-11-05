#!/bin/bash

WakeOnLan() {
  while read tmp_string; do
    hostname=$(echo $tmp_string | awk '{print $1;}')
    addr=$(echo $tmp_string | awk '{print $2;}')
    PROBE_PING=`ping -s 1 -c 2 $hostname".csc.local" &> /dev/null; echo $?`
    if [ $PROBE_PING -eq 0 ];then
      echo -e "\e[1;93m[OStRTA]\e[1;97m\t$hostname is \e[1;92mUP\e[1;97m as on $(date)\e[0;97m"
      exit 0
    elif [ $PROBE_PING -eq 1 ];then
      ether-wake -i enp3s0 $addr | echo -e "\e[1;93m[OStRTA]\e[1;97m\t$hostname is not turned on. WoL-packet sent at $(date +%H:%M)\e[0;97m"
    fi
  done < $mac_path

  sleep 3m | echo -e "\e[1;93m[OStRTA]\e[1;97m\tWaiting 3 Minutes until all hosts wake up...\e[0;97m"

  while read tmp_string; do
    hostname=$(echo $tmp_string | awk '{print $1;}')
    addr=$(echo $tmp_string | awk '{print $2;}')
    PROBE_PING=`ping -s 1 -c 4 $hostname".csc.local" &> /dev/null; echo $?`
    if [ $PROBE_PING -eq 0 ];then
      echo -e "\e[1;93m[OStRTA]\e[1;97m\t$hostname is \e[1;92mUP\e[1;97m as on $(date +%H:%M)\e[0;97m"
    else
      echo -e "\e[1;93m[OStRTA]\e[1;97m\t$(date +%D\ %H:%M) : $hostname is still in \e[1;91mDOWN\e[1;97m state. Checkout connection and host's BIOS settings\e[0;97m"
      echo "$(date +%D\ %H:%M) : $hostname is still in DOWN state." >> ./log/$(date +%d%m%Y).log
    fi
  done < $mac_path
}

SendShutdown() {
  while read tmp_string; do
    hostname=$(echo $tmp_string | awk '{print $1;}')
    PROBE_PING=`ping -s 1 -c 2 $hostname".csc.local" &> /dev/null; echo $?`
    if [ $PROBE_PING -eq 1 ];then
      echo -e "\e[1;93m[OStRTA]\e[1;97m\t$hostname is \e[1;92mDOWN\e[1;97m as on $(date)"
    elif [ $PROBE_PING -eq 0 ];then
      # Who is the last user? We'll know right back
      (ssh -n -o "BatchMode=yes" -o "ConnectTimeout=1" -o "StrictHostKeyChecking=no" $hostname".csc.local" `shutdown 0`)| echo -e "\e[1;93m[OStRTA]\e[1;97m\tHyperion is UP. Poweroff signal sent at $(date +%H:%M)\e[0;97m"
    fi
  done < $mac_path

  sleep 2m | echo -e "\e[1;93m[OStRTA]\e[1;97m\tWaiting 2 Minutes until all hosts shut down...\e[0;97m"

  while read tmp_string; do
    TEST_PING=`ping -s 1 -c 4 $hostname".csc.local" &> /dev/null; echo $?`
    if [ $TEST_PING -eq 0 ];then
      echo -e "\e[1;93m[OStRTA]\e[1;97m\t$(date +%D\ %H:%M) : Host $hostname is still in \e[1;91mUP\e[1;97m state\e[0;97m"
      echo "$(date +%D\ %H:%M) : Shutdown incomplete" >> ./log/$(date +%d%m%Y).log
    else
      echo -e "\e[1;93m[OStRTA]\e[1;97m\t$hostname is \e[1;92mDOWN\e[1;97m as on $(date +%H:%M)\e[0;97m"
    fi
  done < $mac_path
}

WhoIsOnline() {
  echo "Done nothing. Work in progress."
}

#---------------------
# Start of the script
#---------------------

if [ -z "$1" ]; then
  echo -e "\e[1;91mNothing to do.\e[0;97m"
  exit -1
fi

readonly me=$(basename "$0")
readonly template="^.wp[0-9][0-9]"	# regular expression for grep
readonly mac_path="./conf/mac.dat"
ACTION=0

while [ -n "$1" ]; do
  case "$1" in
    -w) echo -e "\n\e[1;93m==>\e[1;97m Initialized hosts' wake up process...\e[0;97m"
    ACTION=1 ;;
    -s)
    if [[ ACTION -eq 1 ]]; then
      echo -e "\n\e[1;91m==>\e[1;97m Do not use keys '-w' and '-s' at the same time.\e[0;97m"
      exit -2
    else
      echo -e "\n\e[1;93m==>\e[1;97m Initialized hosts' poweroff process...\e[0;97m"
      ACTION=2
    fi;;
    -l) echo -e "\n\e[1;93m==>\e[1;97m Searching for active hosts...\e[0;97m"
    ACTION=3 ;;
    -h) echo -e "\n\e[1;97mUsage: ./$me <key>\e[0;97m"
    echo -e "\e[1;97mExample: ./$me -w \e[0;97m"
    echo -e "\n\e[1;97mAvailable keys:\e[0;97m"
    echo -e "\e[1;97m-w : Send Wake-On-LAN packet to the hosts\e[0;97m"
    echo -e "\e[1;97m-s : Send shutdown signal to the hosts\e[0;97m"
    echo -e "\e[1;97m-l : List all active hosts\e[0;97m"
    echo -e "\e[1;97m-h : Print this helpful message and quit\e[0;97m"
    echo -e "\n\e[1;97mNOTE: You are not able to use '-w' and '-p' keys at the same time. Script in Beta.\e[0;97m"
    exit 0 ;;
    *) echo -e "   \e[1;91mUnknow key '$1'...\e[0;97m"
    exit -3;;
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
  exit -4
fi

exit 0
