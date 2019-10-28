#!/bin/bash

MAC=$1

#wake up bwp01 host
echo "Wake up BWP01 with 70:4d:7b:b4:aa:cd"
ether-wake 70:4d:7b:b4:aa:cd
