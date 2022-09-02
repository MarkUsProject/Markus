#!/usr/bin/env bash

THISDIR="$(dirname "${BASH_SOURCE[0]}")"
"${THISDIR}/entrypoint-dev-wait-for-install.sh"

# wait until webpack executables exist
until [ -x node_modules/.bin/webpack ]; do
  echo "waiting for webpack executables to exist"
  sleep 5
done

exec "$@"
