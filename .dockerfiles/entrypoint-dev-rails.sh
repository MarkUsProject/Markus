#!/usr/bin/env bash

# install bundle gems if not up to date with the Gemfile.lock file
bundle check 2>/dev/null || bundle install --without mysql sqlite unicorn

# install yarn packages
yarn install

# install python packages
python3 -m venv ./venv
./venv/bin/pip install -r requirements.txt

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
