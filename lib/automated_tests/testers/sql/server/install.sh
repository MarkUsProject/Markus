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
for datafile in solution/datasets/*; do
	dataname=$(basename -s .sql ${datafile})
	psql -U ate_server -d ate_oracle <<-EOF
		CREATE SCHEMA ${dataname};
		GRANT USAGE ON SCHEMA ${dataname} TO ate_test;
		GRANT SELECT ON ALL TABLES IN SCHEMA ${dataname} TO ate_test;
	EOF
	echo "SET search_path TO ${dataname};" | cat - solution/schema.ddl > /tmp/ate.sql
	psql -U ate_server -d ate_oracle -f /tmp/ate.sql
	echo "SET search_path TO ${dataname};" | cat - ${datafile} > /tmp/ate.sql
	psql -U ate_server -d ate_oracle -f /tmp/ate.sql
	for queryfile in solution/queries/*; do
    	echo "SET search_path TO ${dataname};" | cat - ${queryfile} > /tmp/ate.sql
		psql -U ate_server -d ate_oracle -f /tmp/ate.sql
	done
done
rm /tmp/ate.sql
