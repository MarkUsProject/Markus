#!/usr/bin/env bash
# Runs a command in the rails Docker Compose service. Used by pre-commit hooks so
# that their tools come from the container's bundle rather than a local install.
#
# Runs the command directly when already inside a container or on CI.

if [ -f /.dockerenv ] || [ -n "$CI" ]; then
  exec "$@"
fi

if [ -n "$(docker compose ps --status running --quiet rails 2>/dev/null)" ]; then
  exec docker compose exec -T rails "$@"
else
  exec docker compose --progress quiet run --rm --no-deps -T --entrypoint "" rails "$@"
fi
