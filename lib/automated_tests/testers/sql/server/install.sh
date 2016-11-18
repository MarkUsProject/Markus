#!/usr/bin/env bash

if [ $# -ne 1 ]; then
	echo usage: $0 install_dir
	exit 1
fi

INSTALLDIR=$1
SERVERDB=ate_oracle
SERVERUSER=ate_server
SERVERPWD=YOUR_SERVER_PASSWORD
TESTDB=ate_tests
TESTUSER=ate_test
TESTPWD=YOUR_TEST_PASSWORD
SOLUTIONDIR=solution
SCHEMAFILE=schema.ddl
DATASETDIR=datasets
QUERYDIR=queries
cd ${INSTALLDIR}
sudo -u postgres psql <<-EOF
	CREATE ROLE ${SERVERUSER} LOGIN PASSWORD '${SERVERPWD}';
	CREATE ROLE ${TESTUSER} LOGIN PASSWORD '${TESTPWD}';
	CREATE DATABASE ${SERVERDB} OWNER ${SERVERUSER};
	CREATE DATABASE ${TESTDB} OWNER ${TESTUSER};
EOF
for datafile in ${SOLUTIONDIR}/${DATASETDIR}/*; do
	dataname=$(basename -s .sql ${datafile})
	psql -U ${SERVERUSER} -d ${SERVERDB} <<-EOF
		CREATE SCHEMA ${dataname};
		GRANT USAGE ON SCHEMA ${dataname} TO ${TESTUSER};
	EOF
	echo "SET search_path TO ${dataname};" | cat - ${SOLUTIONDIR}/${SCHEMAFILE} > /tmp/ate.sql
	psql -U ${SERVERUSER} -d ${SERVERDB} -f /tmp/ate.sql
	echo "SET search_path TO ${dataname};" | cat - ${datafile} > /tmp/ate.sql
	psql -U ${SERVERUSER} -d ${SERVERDB} -f /tmp/ate.sql
	for queryfile in ${SOLUTIONDIR}/${QUERYDIR}/*; do
    	echo "SET search_path TO ${dataname};" | cat - ${queryfile} > /tmp/ate.sql
		psql -U ${SERVERUSER} -d ${SERVERDB} -f /tmp/ate.sql
	done
	psql -U ${SERVERUSER} -d ${SERVERDB} <<-EOF
		GRANT SELECT ON ALL TABLES IN SCHEMA ${dataname} TO ${TESTUSER};
	EOF
done
rm /tmp/ate.sql
