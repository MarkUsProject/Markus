#!/usr/bin/env bash

if [ $# -ne 4 ]; then
    echo usage: $0 server_user server_host server_basedir course_name
    exit 1
fi
USER=$1
SERVER=$2
BASEDIR=$3
COURSE=$4
VENVDIR=venvs
ssh ${USER}@${SERVER} bash -c "'
    cd ${BASEDIR}
    mkdir -p ${VENVDIR}
    pyvenv ${VENVDIR}/${COURSE}
    source ${VENVDIR}/${COURSE}/bin/activate
    pip install wheel testtools
'"
