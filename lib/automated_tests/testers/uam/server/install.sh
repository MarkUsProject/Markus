#!/usr/bin/env bash

if [ $# -ne 4 ]; then
    echo usage: $0 server_user server_host server_install_dir server_pythonpath_dir
    exit 1
fi
USER=$1
SERVER=$2
INSTALLDIR=$3
PYTHONPATHDIR=$4
UAMDIR=uam
ssh ${USER}@${SERVER} bash -c "'
    cd ${INSTALLDIR}
    if cd ${UAMDIR}; then
        git pull
        cd ..
    else
        git clone https://github.com/ProjectAT/uam.git ${UAMDIR}
    fi
'"
scp pam_wrapper.py markus_pam_wrapper.py ../../../markusapi/markusapi.py ${USER}@${SERVER}:${PYTHONPATHDIR}
