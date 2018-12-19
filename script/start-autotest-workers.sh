#!/usr/bin/env bash

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 markus-autotesting-root-dir"
else
  AUTOTEST_ROOT=$(readlink -f "$1")
fi

echo "[MARKUS] Starting autotest workers using supervisord"
source "${AUTOTEST_ROOT}"/server/venv/bin/activate
pushd "${AUTOTEST_ROOT}"/server/workspace/logs > /dev/null
supervisord -c supervisord.conf
popd > /dev/null
deactivate
