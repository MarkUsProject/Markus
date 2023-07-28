#!/bin/bash

########################################################################
# Basic structure as to how a password validation script might look like
# The preferred way is to write a small C program for this though.
########################################################################

# Check that no username/passwords are passed on the command line
if [ "$#" -ne 0 ]; then
	# HACK-ALARM?!
	echo "usage: $0" 1>&2
	exit 1
fi

# Username is passed on the first line from stdin, the users
# password as the second line. ip address might optionally be passed
# as a third line
# WARNING: username and/or password may contain any characters except \n
# 		   and \0. I.e. don't trust that data in any case. Thus, make
#		   sure your script/program accounts for that!
read user
read password
read ip

########################################################################
# Do your password validation here
########################################################################

if [ $user == 'exit1' ]; then
  exit 1
fi

if [ $user == 'exit2' ]; then
  exit 2
fi

if [ $user == 'exit3' ]; then
  echo "custom message with error 3"
  exit 3
fi

if [ $user == 'exit3nomsg' ]; then
  exit 3
fi

if [ $user == 'exit4' ]; then
  echo "custom message with error 4"
  exit 4
fi

# Exit with 0 return code, if and only if user/password combination
# is valid
exit 0
