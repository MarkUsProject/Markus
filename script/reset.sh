#!/usr/bin/env bash

THIS_SCRIPT=$(readlink -f "${BASH_SOURCE}")
THIS_SCRIPT_DIR=$(dirname "${THIS_SCRIPT}")
MARKUS_ROOT=$(readlink -f "${THIS_SCRIPT_DIR}/..")
AUTOTEST_ROOT=$(readlink -f "${MARKUS_ROOT}/../markus-autotesting")

echo "[MARKUS] Shutting down existing MarkUs processes"
pkill -f rails
pkill -f resque
pkill -KILL -f webpack-dev-server # shuts down only with a -KILL

echo "[MARKUS] Shutting down existing autotest processes"
pkill -f supervisord

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
redis-cli --raw DUMP autotest:workers | head -c-1 >| /tmp/.redis.tmp # make the dump play nice with shell commands
redis-cli FLUSHDB
cat /tmp/.redis.tmp | redis-cli -x RESTORE autotest:workers 0

echo "[MARKUS] Resetting MarkUs database"
pushd "${MARKUS_ROOT}" > /dev/null
bundle exec rake db:reset
popd > /dev/null

echo "[MARKUS] Restarting MarkUs"
"${MARKUS_ROOT}"/script/start-autotest-workers.sh
"${MARKUS_ROOT}"/bin/markus
