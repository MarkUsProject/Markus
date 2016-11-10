#!/usr/bin/env bash

if [ $# -ne 1 ]; then
	echo usage: $0 install_dir
	exit 1
fi

INSTALLDIR=$1
SERVERPWD=YOUR_SERVER_PASSWORD
TESTPWD=YOUR_TEST_PASSWORD
SOLUTIONDIR=solution
SCHEMAFILE=schema.ddl
DATASETDIR=datasets
QUERYDIR=queries
cd ${INSTALLDIR}
sudo -u postgres psql <<-EOF
	CREATE ROLE ate_server LOGIN PASSWORD '${SERVERPWD}';
	CREATE ROLE ate_test LOGIN PASSWORD '${TESTPWD}';
	CREATE DATABASE ate_oracle OWNER ate_server;
	CREATE DATABASE ate_tests OWNER ate_test;
EOF
for datafile in ${SOLUTIONDIR}/${DATASETDIR}/*; do
	dataname=$(basename -s .sql ${datafile})
	psql -U ate_server -d ate_oracle <<-EOF
		CREATE SCHEMA ${dataname};
		GRANT USAGE ON SCHEMA ${dataname} TO ate_test;
	EOF
	echo "SET search_path TO ${dataname};" | cat - ${SOLUTIONDIR}/${SCHEMAFILE} > /tmp/ate.sql
	psql -U ate_server -d ate_oracle -f /tmp/ate.sql
	echo "SET search_path TO ${dataname};" | cat - ${datafile} > /tmp/ate.sql
	psql -U ate_server -d ate_oracle -f /tmp/ate.sql
	for queryfile in ${SOLUTIONDIR}/${QUERYDIR}/*; do
    	echo "SET search_path TO ${dataname};" | cat - ${queryfile} > /tmp/ate.sql
		psql -U ate_server -d ate_oracle -f /tmp/ate.sql
	done
	psql -U ate_server -d ate_oracle <<-EOF
		GRANT SELECT ON ALL TABLES IN SCHEMA ${dataname} TO ate_test;
	EOF
done
rm /tmp/ate.sql
