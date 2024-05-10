#!/bin/bash

read user
read password
read ip

if [ ! "$ip" == "0.0.0.0" ]; then
  exit 1
  fi
exit 0
