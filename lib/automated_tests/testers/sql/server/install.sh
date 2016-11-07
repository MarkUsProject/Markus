#!/usr/bin/env bash

if [ $# -ne 2 ]; then
    echo usage: $0 install_dir schema_name
    exit 1
fi

INSTALLDIR=$1
SCHEMA=$2
SERVERPWD=YOUR_SERVER_PASSWORD
TESTPWD=YOUR_TEST_PASSWORD
cd ${INSTALLDIR}
sudo -u postgres psql <<-EOF
    CREATE ROLE ate_server LOGIN PASSWORD '${SERVERPWD}';
    CREATE ROLE ate_test LOGIN PASSWORD '${TESTPWD}';
    CREATE DATABASE ate_oracle OWNER ate_server;
    CREATE DATABASE ate_tests OWNER ate_test;
EOF
for datafile in solution/datasets; do
    dataname=TODO #TODO get file name
    psql -U ate_server -d ate_oracle <<-EOF
        CREATE SCHEMA ${dataname};
        SET search_path TO ${dataname};
        GRANT USAGE ON SCHEMA ${dataname} TO ate_test;
        GRANT SELECT ON ALL TABLES IN SCHEMA ${dataname} TO ate_test;
    EOF
    psql -U ate_server -d ate_oracle -f solution/schema.ddl
    psql -U ate_server -d ate_oracle -f solution/datasets/${datafile}
    for queryfile in solution/queries; do
        psql -U ate_server -d ate_oracle -f solution/queries/${queryfile}
    done
done
