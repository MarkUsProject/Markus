#!/bin/bash

########################################################################
# Basic structure as to how a password validation script might look like
########################################################################
# Username is passed in as the first argument, the users
# password as a second argument.

user="$1"
shift
pw="$1"
shift

# Check if 2 params have been passed, only
if [ "${1}_" != "_" ]; then
	# HACK-ALARM?!
	echo "MarkUs passed a third argument, something's smelly here!" 1>&2
	exit 1
fi


########################################################################
# Do your password validation here
########################################################################


# Exit with 0 return code, if and only if user/password combination
# is valid
exit 0

