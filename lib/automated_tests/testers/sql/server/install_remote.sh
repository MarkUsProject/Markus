#!/usr/bin/env bash

if [ $# -ne 4 ]; then
	echo usage: $0 server_user server_host server_install_dir server_pythonpath_dir
	exit 1
fi

USER=$1
SERVER=$2
INSTALLDIR=$3
PYTHONPATHDIR=$4
scp -r solution ${USER}@${SERVER}:${INSTALLDIR}
scp markus_sql_config.py markus_sql_tester.py ${USER}@${SERVER}:${PYTHONPATHDIR}
ssh ${USER}@${SERVER} bash -s -- < install.sh ${INSTALLDIR}
# TODO create sql root dir + venv subdir with files to be imported instead of pythonpath
