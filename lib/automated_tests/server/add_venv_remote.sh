#!/usr/bin/env bash

if [ $# -ne 5 ]; then
    echo usage: $0 server_user server_host server_install_dir venv_name pip_requirements_file
    exit 1
fi
USER=$1
SERVER=$2
INSTALLDIR=$3
NAME=$4
REQUIREMENTS=$5
VENVDIR=venvs
scp ${REQUIREMENTS} ${USER}@${SERVER}:${INSTALLDIR}
ssh ${USER}@${SERVER} bash -s -- < add_venv.sh ${INSTALLDIR} ${NAME}
