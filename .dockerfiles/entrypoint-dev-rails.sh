#!/usr/bin/env bash

# install bundle gems if not up to date with the Gemfile.lock file
bundle check 2>/dev/null || bundle install --without mysql sqlite unicorn

# install yarn packages if not up to date with yarn.lock file
yarn check --integrity 2>/dev/null || yarn install --check-files

# setup the database (checks for db existence first)
cp .dockerfiles/database.yml.postgresql config/database.yml
until psql "postgres://${PGUSER}:${PGPASSWORD}@${PGHOST}:5432/postgres" -lqt &>/dev/null; do
  echo "waiting for database to start up"
  sleep 5
done
psql "postgres://${PGUSER}:${PGPASSWORD}@${PGHOST}:5432" -lqt 2> /dev/null | cut -d \| -f 1 | grep -wq "${PGDATABASE}" || rails db:setup

rm -f ./tmp/pids/server.pid

# Then exec the container's main process (what's set as CMD in the Dockerfile or docker-compose.yml).
exec "$@"
