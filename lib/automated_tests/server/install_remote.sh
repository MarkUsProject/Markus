#!/usr/bin/env bash

if [ $# -ne 5 ]; then
	echo usage: $0 server_user server_host server_install_dir server_pythonpath_dir server_queue_name
	exit 1
fi

USER=$1
SERVER=$2
INSTALLDIR=$3
PYTHONPATHDIR=$4
QUEUE=$5
scp automated_tests_server.rb Gemfile Gemfile.lock Rakefile ${USER}@${SERVER}:${INSTALLDIR}
scp python_apis/markusapi.py python_apis/markus_utils.py ${USER}@${SERVER}:${PYTHONPATHDIR}
ssh ${USER}@${SERVER} bash -s -- < install.sh ${INSTALLDIR} ${QUEUE}
