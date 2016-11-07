#!/usr/bin/env bash

if [ $# -ne 5 ]; then
	echo usage: $0 server_user server_host server_install_dir server_pythonpath_dir schema_name
	exit 1
fi

USER=$1
SERVER=$2
INSTALLDIR=$3
PYTHONPATHDIR=$4
SCHEMA=$5
scp -r solution ${USER}@${SERVER}:${INSTALLDIR}
scp markus_sql_config.py ${USER}@${SERVER}:${PYTHONPATHDIR}
ssh ${USER}@${SERVER} bash -s -- < install.sh ${INSTALLDIR} ${SCHEMA}
