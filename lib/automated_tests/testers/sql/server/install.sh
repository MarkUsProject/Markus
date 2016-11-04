#!/usr/bin/env bash

if [ $# -ne 4 ]; then
    echo usage: $0 server_user server_host server_install_dir server_pythonpath_dir
    exit 1
fi

USER=$1
SERVER=$2
INSTALLDIR=$3
PYTHONPATHDIR=$4
SERVERPWD=YOUR_SERVER_PASSWORD
TESTPWD=YOUR_TEST_PASSWORD
scp schema.ddl data.sql ${USER}@${SERVER}:${INSTALLDIR}
scp markus_sql_config.py ${USER}@${SERVER}:${PYTHONPATHDIR}
ssh ${USER}@${SERVER} bash -c "'
    cd ${INSTALLDIR}
    sudo -u postgres psql <<-EOF
        CREATE ROLE ate_server CREATEDB LOGIN PASSWORD '${SERVERPWD}';
        CREATE ROLE ate_test LOGIN PASSWORD '${TESTPWD}';
        CREATE DATABASE ate_tests OWNER ate_server;
    EOF
    psql -U ate_server -d ate_tests -f schema.ddl
    psql -U ate_server -d ate_tests -f data.sql
'"
