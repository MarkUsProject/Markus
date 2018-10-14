#!/usr/bin/env bash

THIS_SCRIPT=$(readlink -f "${BASH_SOURCE}")
THIS_SCRIPT_DIR=$(dirname "${THIS_SCRIPT}")
MARKUS_ROOT=$(readlink -f "${THIS_SCRIPT_DIR}/..")
AUTOTEST_ROOT=$(readlink -f "${MARKUS_ROOT}/../markus-autotesting")

echo "[MARKUS] Shutting down existing MarkUs processes"
pkill -TERM -f rails
pkill -TERM -f resque
pkill -KILL -f webpack-dev-server # shuts down only with a -KILL

echo "[MARKUS] Shutting down existing autotest processes"
pkill -TERM -f supervisord # should not be a -KILL or the rq workers will stay alive

echo "[MARKUS] Removing old MarkUs files"
rm -rf "${MARKUS_ROOT}"/data/dev/autotest/*
rm -rf "${MARKUS_ROOT}"/data/dev/exam_templates/*
rm -rf "${MARKUS_ROOT}"/data/dev/repos/*
rm -rf "${MARKUS_ROOT}"/log/*
rm -rf "${MARKUS_ROOT}"/public/javascripts
rm -rf "${MARKUS_ROOT}"/public/packs
rm -rf "${MARKUS_ROOT}"/tmp/cache

echo "[MARKUS] Removing old autotest files"
rm -rf "${AUTOTEST_ROOT}"/server/workspace/scripts/*
rm -rf "${AUTOTEST_ROOT}"/server/workspace/results/*

echo "[MARKUS] Removing old redis entries"
pushd "${AUTOTEST_ROOT}"/server > /dev/null
REDIS_WORKERS=$(python3 -c "import config as c; print(f'{c.REDIS_PREFIX}:{c.REDIS_WORKERS_LIST}')")
popd > /dev/null
redis-cli --raw DUMP ${REDIS_WORKERS} | head -c-1 >| /tmp/.redis.tmp # make the dump play nice with shell commands
redis-cli FLUSHDB
cat /tmp/.redis.tmp | redis-cli -x RESTORE ${REDIS_WORKERS} 0

echo "[MARKUS] Resetting MarkUs database"
pushd "${MARKUS_ROOT}" > /dev/null
bundle exec rake i18n:js:export
bundle exec rake db:reset
popd > /dev/null

echo "[MARKUS] Restarting MarkUs"
"${MARKUS_ROOT}"/script/start-autotest-workers.sh
"${MARKUS_ROOT}"/bin/markus
