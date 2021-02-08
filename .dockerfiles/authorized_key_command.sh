#!/usr/bin/env bash

HOMEDIR=$1
shopt -s globstar
cat "${HOMEDIR}"/**/.authorized_keys
