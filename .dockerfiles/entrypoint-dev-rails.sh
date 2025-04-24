#!/usr/bin/env bash

# Enable jemalloc for reduced memory usage and latency.
if [ -z "${LD_PRELOAD+x}" ] && [ -f /usr/lib/*/libjemalloc.so.2 ]; then
  export LD_PRELOAD="$(echo /usr/lib/*/libjemalloc.so.2)"
fi

# setup the database (checks for db existence first)
until pg_isready -q; do
  echo "waiting for database to start up"
  sleep 5
done

# sets up the database if it doesn't exist
cp .dockerfiles/database.yml.postgresql config/database.yml
bundle exec rails db:prepare

# strip newlines from end of structure.sql (revert when/if https://github.com/rails/rails/pull/46454 is implemented)
sed -i -e :a -e '/^\n*$/{$d;N;};/\n$/ba' /app/db/structure.sql

rm -f ./tmp/pids/server.pid

# cssbundling-rails development command
npm run build-dev:css &

# Then exec the container's main process (what's set as CMD in the Dockerfile or compose.yaml).
exec "$@"
