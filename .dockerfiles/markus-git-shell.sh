#!/bin/bash

[[ -z ${LOGIN_USER} ]] && exit 1 # LOGIN_USER must be set
[[ -z ${RELATIVE_URL_ROOT} ]] && exit 1 # RELATIVE_URL_ROOT must be set

GIT_ACCESS_FILE="${HOME}/.ssh/${RELATIVE_URL_ROOT}/.access"

[[ -f ${GIT_ACCESS_FILE} ]] || exit 1 # access file must exist

AVAILABLE_REPOS=$(grep -P ",${LOGIN_USER}(?:,|\s*$)" "${GIT_ACCESS_FILE}" | cut -f1 -d,)
REQUESTED_REPO_PATH=$(basename "$(echo "$SSH_ORIGINAL_COMMAND" | cut -f2 -d' ')")
REQUESTED_REPO="${REQUESTED_REPO_PATH%.*}"

grep -qP "^${REQUESTED_REPO%.*}|\*$" <(echo "${AVAILABLE_REPOS}") || exit 1 # must have permission to access the repo

sudo /usr/bin/git-shell -c "$SSH_ORIGINAL_COMMAND"
