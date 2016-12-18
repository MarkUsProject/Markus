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
scp pam_wrapper.py markus_pam_wrapper.py ${USER}@${SERVER}:${PYTHONPATHDIR}
ssh ${USER}@${SERVER} bash -s -- < install.sh ${INSTALLDIR}
# TODO create uam root dir + venv subdir with files to be imported instead of pythonpath
