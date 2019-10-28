#!/bin/bash

readonly me=$(basename "$0")
ENABLE_ALL=0
WAKE=0
SHUT=0

while [ -n "$1" ]; do
  case "$1" in
    -a) ENABLE_ALL=1
    shift ;;
    -w) echo -e "\n\e[1;93m==>\e[1;97m Initializing hosts wake up process...\e[0;97m"
    WAKE=1 ;;
    -s) echo -e "\n\e[1;93m==>\e[1;97m Initializing hosts shutdown process...\e[0;97m"
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
