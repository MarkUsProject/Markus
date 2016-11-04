#!/usr/bin/env bash

if [ $# -ne 4 ]; then
    echo usage: $0 server_user server_host server_install_dir server_pythonpath_dir
    exit 1
fi

USER=$1
SERVER=$2
INSTALLDIR=$3
PYTHONPATHDIR=$4
QUEUE=ate_tests
scp automated_tests_server.rb Gemfile Gemfile.lock Rakefile ${USER}@${SERVER}:${INSTALLDIR}
scp python_apis/markusapi.py python_apis/markus_utils.py ${USER}@${SERVER}:${PYTHONPATHDIR}
ssh ${USER}@${SERVER} bash -c "'
    cd ${INSTALLDIR}
    bundle install --deployment
    TERM_CHILD=1 BACKGROUND=yes QUEUES=${QUEUE} bundle exec rake resque:work
'"
