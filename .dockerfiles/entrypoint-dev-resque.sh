#!/usr/bin/env bash

THISDIR="$(dirname "${BASH_SOURCE[0]}")"
"${THISDIR}/entrypoint-dev-wait-for-install.sh"

BACKGROUND=true bundle exec rails resque:scheduler
exec "$@"
