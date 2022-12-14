#!/usr/bin/env bash

# wait until gems are installed (crucially, wait for jsbundling-rails to be installed)
until bundle check &> /dev/null; do
  echo "waiting for gems to be installed"
  sleep 5
done

# wait until npm packages are installed
until npm list &>/dev/null; do
  echo "waiting for npm packages to be installed"
  sleep 5
done

# execute the command normally
exec "$@"
