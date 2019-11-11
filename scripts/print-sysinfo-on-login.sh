#!/bin/bash

# Description: This script display some system information that you select when a user logs in.
# How-to-use: Uncomment the functions at the end of this script to enable the display of the necessary information.
# Place this script in the '/etc/profile.d/' directory.
#
# Author: Alex Anenkov
# Version: 1.0.0


# Prevent duplication
if [ -z "$SYSINFO_ON_LOGIN_SHOWED" ] && [[ $- == *i* ]]; then
    export SYSINFO_ON_LOGIN_SHOWED=1
else
    return 1
fi


print_uptime() {
    output=$(uptime | awk -F'( |,|:)+' '{if ($7=="min") m=$6; else {if ($7~/^day/) {d=$6;h=$8;m=$9} else {h=$6;m=$7}}} {print d+0,"days,",h+0,"hours,",m+0,"minutes"}')
    printf "  %-25s %-20s\n" "Uptime:" "$output"
}

print_ram_usage() {
    output=$(free -m | awk 'NR==2{printf "%s/%sMB (%.2f%%)\n", $3,$2,$3*100/$2 }')
    printf "  %-25s %-20s\n" "RAM usage:" "$output"
}

print_cpu_load() {
    output=$(uptime | grep load | awk '{printf "%.2f\n", $(NF-2)}')
    printf "  %-25s %-20s\n" "CPU load:" "$output"
}

print_services_states() {
    for service in $1; do
        if (systemctl -q is-active $service.service); then
            output="\e[00;32mactive (running)\e[0m"     # green text
        else
            output="\e[00;31msomething wrong!\e[0m"     # red text
        fi
        printf "  %-25s %-20b\n" "$service service:" "$output"
    done
}

print_raid_status() {
    if [ -f /proc/mdstat ]; then
        if [ -z "$(egrep '\[.*_.*\]' /proc/mdstat)" ]; then
            output="\e[00;32mok\e[0m"       # green text
        else
            output="\e[00;31msomething wrong!\e[0m"     # red text
        fi
        printf "  %-25s %-20b\n" "RAID status:" "$output"
    fi
}


echo


# Just uncomment the functions below
# to enable the display of the necessary information.

print_uptime;
print_ram_usage;
print_cpu_load;
print_services_states "named-chroot dhcpd ypserv nfs-server"; # you can edit this string by adding the services you need by separating them with a space
print_raid_status;


echo
