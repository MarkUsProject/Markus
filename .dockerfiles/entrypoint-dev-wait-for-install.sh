#!/usr/bin/env bash

# wait until gems are installed (crucially, wait for jsbundling-rails to be installed)
until bundle check &> /dev/null; do
  echo "waiting for gems to be installed"
  sleep 5
done

# wait until yarn packages are installed
until yarn install --immutable --immutable-cache &>/dev/null; do
  echo "waiting for yarn packages to be installed"
  sleep 5
done

# execute the command normally
exec "$@"
