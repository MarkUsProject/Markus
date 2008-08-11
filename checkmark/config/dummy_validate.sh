#!/bin/bash

read user
read pw

if [ "$user" == "" -o "$pw" == "" ]
then
  exit 1
fi

exit 0

