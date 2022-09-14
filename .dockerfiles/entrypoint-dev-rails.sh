#!/usr/bin/env bash

# install bundle gems if not up to date with the Gemfile.lock file
bundle check 2>/dev/null || bundle install --without unicorn

# install node packages
npm list &> /dev/null || npm ci

# install python packages
[ -f ./venv/bin/pip ] || python3 -m venv ./venv
./venv/bin/python3 -m pip install --upgrade pip > /dev/null
./venv/bin/pip install -r requirements-jupyter.txt -r requirements-scanner.txt > /dev/null

# setup the database (checks for db existence first)
cp .dockerfiles/database.yml.postgresql config/database.yml
until psql "postgres://${PGUSER}:${PGPASSWORD}@${PGHOST}:${PGPORT}/postgres" -lqt &>/dev/null; do
  echo "waiting for database to start up"
  sleep 5
done
psql "postgres://${PGUSER}:${PGPASSWORD}@${PGHOST}:${PGPORT}" -lqt 2> /dev/null | cut -d \| -f 1 | grep -wq "${PGDATABASE}" || rails db:setup

rm -f ./tmp/pids/server.pid

# Then exec the container's main process (what's set as CMD in the Dockerfile or docker-compose.yml).
exec "$@"
