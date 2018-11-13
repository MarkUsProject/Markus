#!/usr/bin/env bash

if [ $# -ne 1 ]; then
  echo "Usage: $0 markus-autotesting-root-dir"
else
  AUTOTEST_ROOT="$1"
fi

echo "[MARKUS] Starting autotest workers using supervisord"
source "${AUTOTEST_ROOT}"/server/venv/bin/activate
pushd "${AUTOTEST_ROOT}"/server/workspace > /dev/null
supervisord -c "${AUTOTEST_ROOT}"/server/supervisord.conf
popd > /dev/null
deactivate
