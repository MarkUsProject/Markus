#!/usr/bin/env bash

# This script finds all .authorized_keys lines associated with markus instances
# from each instance's database and writes their content to stdout.
# This file should be called by the ssh daemon's AuthorizedKeysCommand.

HOME_DIR=${1:-${HOME}}

while IFS= read -r service; do
  psql service="${service}" -qtA -c 'SELECT get_authorized_keys()'
done < <(sed -n "s/^\[\(.*\)\]\s*$/\1/p" "${HOME_DIR}/.pg_service.conf")
