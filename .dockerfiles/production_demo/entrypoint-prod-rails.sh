#!/usr/bin/env bash

until psql "postgres://${PGUSER}:${PGPASSWORD}@${PGHOST}:${PGPORT}/postgres" -lqt &>/dev/null; do
  echo "waiting for database to start up"
  sleep 5
done
psql "postgres://${PGUSER}:${PGPASSWORD}@${PGHOST}:${PGPORT}" -lqt 2> /dev/null | cut -d \| -f 1 | grep -wq "${PGDATABASE}" || bundle exec rails db:create db:migrate

rm -f ./tmp/pids/server.pid

# Then exec the container's main process (what's set as CMD in the Dockerfile or docker-compose.yml).
exec "$@"
