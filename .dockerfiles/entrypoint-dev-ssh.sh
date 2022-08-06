#!/usr/bin/env bash

cp /app/lib/repo/authorized_key_command.sh /usr/local/bin/authorized_key_command.sh

exec "$@"
