#!/usr/bin/env bash

HOMEDIR=$1
cat "${HOMEDIR}"/.ssh/authorized_keys "${HOMEDIR}"/*/.authorized_keys 2> /dev/nulls
