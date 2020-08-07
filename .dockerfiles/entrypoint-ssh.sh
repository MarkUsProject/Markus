#!/usr/bin/env bash

AUTHORIZED_KEY_FILES=$(echo "${RELATIVE_URL_ROOTS}" | sed -E "s@([^:]+):?@/home/${SSH_USER}/.ssh\1/authorized_keys @g")

if [[ -z "${AUTHORIZED_KEY_FILES}" ]]; then
  >&2 echo 'RELATIVE_URL_ROOTS is not set'
  exit 1
fi

if grep -q AuthorizedKeysFile /etc/ssh/sshd_config; then
  sed -i "s@#*AuthorizedKeysFile.*@AuthorizedKeysFile ${AUTHORIZED_KEY_FILES}@g" /etc/ssh/sshd_config
else
  echo "AuthorizedKeysFile ${AUTHORIZED_KEY_FILES}" >> /etc/ssh/sshd_config
fi

exec "$@"
