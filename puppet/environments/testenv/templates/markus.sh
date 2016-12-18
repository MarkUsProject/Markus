#!/usr/bin/env bash

# Usage: markus.sh        # Start the server, only 
#        markus.sh init   # Initialize the databases and start the server.
# Can set environment variable RAILS_ENV to one of development, test, and production.

RAILS_ENV="${RAILS_ENV:-development}"
export RAILS_ENV
cd /vagrant

if [ "$1x" == "initx" ]; then
	bundle exec rake db:create && bundle exec rake db:schema:load && bundle exec rake db:migrate && bundle exec rake db:seed
fi
bundle exec rails s
