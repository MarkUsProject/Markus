#!/usr/bin/env bash

if [ $# -ne 2 ]; then
	echo usage: $0 install_dir queue_name
	exit 1
fi

INSTALLDIR=$1
QUEUE=$2
cd ${INSTALLDIR}
bundle install --deployment
TERM_CHILD=1 BACKGROUND=yes QUEUES=${QUEUE} bundle exec rake resque:work
