#!/usr/bin/env bash

THIS_SCRIPT=$(readlink -f "${BASH_SOURCE}")
THIS_SCRIPT_DIR=$(dirname "${THIS_SCRIPT}")
AUTOTEST_ROOT=$(readlink -f "${THIS_SCRIPT_DIR}/../../markus-autotesting")

echo "[MARKUS] Starting autotest workers using supervisord"
source "${AUTOTEST_ROOT}"/server/venv/bin/activate
pushd "${AUTOTEST_ROOT}"/server/workspace > /dev/null
supervisord -c "${AUTOTEST_ROOT}"/server/supervisord.conf
popd > /dev/null
deactivate
