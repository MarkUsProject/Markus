#!/usr/bin/env bash

HOMEDIR=$1

cat "${HOMEDIR}"/.ssh/*/authorized_keys
