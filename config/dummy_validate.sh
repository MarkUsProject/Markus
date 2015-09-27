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
# password as the second line.
# WARNING: username and/or password may contain any characters except \n
# 		   and \0. I.e. don't trust that data in any case. Thus, make
#		   sure your script/program accounts for that!
read user
read password


########################################################################
# Do your password validation here
########################################################################


# Exit with 0 return code, if and only if user/password combination
# is valid
exit 0
