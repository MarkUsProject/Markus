#!/usr/bin/env bash

# install bundle gems if not up to date with the Gemfile.lock file
bundle check 2>/dev/null || bundle install --without unicorn

# install node packages
npm list &> /dev/null || npm ci

# install python packages
[ -f ./venv/bin/python3 ] || python3 -m venv ./venv
./venv/bin/python3 -m pip install --upgrade pip > /dev/null
./venv/bin/python3 -m pip install -r requirements-jupyter.txt
./venv/bin/python3 -m pip install -r requirements-scanner.txt
./venv/bin/python3 -m pip install -r requirements-qr.txt

# install chromium (for nbconvert webpdf conversion)
./venv/bin/python3 -m playwright install chromium

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

# Then exec the container's main process (what's set as CMD in the Dockerfile or compose.yaml).
exec "$@"
