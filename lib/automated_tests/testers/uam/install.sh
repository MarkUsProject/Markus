#!/usr/bin/env bash

if [ $# -ne 3 ]; then
    echo usage: $0 server_user server_host server_basedir
    exit 1
fi
USER=$1
SERVER=$2
BASEDIR=$3
ssh ${USER}@${SERVER} bash -c "'
    cd ${BASEDIR}
    if cd uam; then
        git pull
        cd ..
    else
        git clone https://github.com/ProjectAT/uam.git uam
    fi
    mkdir -p libs
'"
scp pam_wrapper.py markus_pam_wrapper.py ../../markusapi/markusapi.py ${USER}@${SERVER}:${BASEDIR}/libs
