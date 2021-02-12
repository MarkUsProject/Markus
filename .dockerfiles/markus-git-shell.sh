#!/bin/bash

set -eE -o functrace

LOG_FILE="${LOG_FILE:-${HOME}/log/ssh.log}"
GIT_SHELL="${GIT_SHELL:-git-shell}"
GIT_ACCESS_FILE="${HOME}/${RELATIVE_URL_ROOT}/.access"

write_log() {
  echo "$(date): ${1}" >> "${LOG_FILE}"
}

failure() {
  write_log "UNEXPECTED ERROR: ${1}"
}

trap 'failure "$BASH_COMMAND"' ERR

[[ -z ${LOGIN_USER} ]] && write_log 'ERROR: LOGIN_USER not set' && exit 1
[[ ! -f ${GIT_ACCESS_FILE} ]] && write_log "ERROR: file does not exist: ${GIT_ACCESS_FILE}" && exit 1

AVAILABLE_REPOS=$(grep -P ",${LOGIN_USER}(?:,|\s*$)" "${GIT_ACCESS_FILE}" | cut -f1 -d,)
REQUESTED_REPO_PATH=$(basename "$(echo "${SSH_ORIGINAL_COMMAND}" | cut -f2 -d' ')")
REQUESTED_REPO="${REQUESTED_REPO_PATH%.*}"

if grep -qP "^${REQUESTED_REPO%.*}|\*$" <(echo "${AVAILABLE_REPOS}"); then
  ${GIT_SHELL} -c "${SSH_ORIGINAL_COMMAND}"
  write_log "SUCCESS: LOGIN_USER=${LOGIN_USER} RELATIVE_URL_ROOT=${RELATIVE_URL_ROOT}, cmd=${SSH_ORIGINAL_COMMAND}"
else
  write_log "PERMISSION DENIED: LOGIN_USER=${LOGIN_USER}, RELATIVE_URL_ROOT=${RELATIVE_URL_ROOT}, cmd=${SSH_ORIGINAL_COMMAND}"
  exit 1
fi
