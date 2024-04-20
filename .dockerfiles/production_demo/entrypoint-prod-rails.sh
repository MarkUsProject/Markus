#!/usr/bin/env bash

until pg_isready -q; do
  echo "waiting for database to start up"
  sleep 5
done

bundle exec rails db:prepare

rm -f ./tmp/pids/server.pid

# Then exec the container's main process (what's set as CMD in the Dockerfile or compose.yaml).
exec "$@"
