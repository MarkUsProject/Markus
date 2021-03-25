#!/usr/bin/env bash

# This script finds all .authorized_keys files associated with markus instances
# and writes their content to stdout.
# This file should be called by the ssh daemon's AuthorizedKeysCommand.

# shellcheck disable=SC1090
source "${HOME}/.ssh/rc"

# The MARKUS_REPO_LOC_PATTERN environment variable must be set
#
# It is highly recommended that the MARKUS_REPO_LOC_PATTERN variable sourced from the "${HOME}/.ssh/rc"
# file (see above). You may also hard-code it in this file directly if you wish or source them from another
# file. If you do either, you must modify this file accordingly.
[[ -z ${MARKUS_REPO_LOC_PATTERN} ]] && echo 'ERROR: MARKUS_REPO_LOC_PATTERN not set' 1>&2 && exit 1

# Convert the MARKUS_REPO_LOC_PATTERN to an actual path that points to a repository on disk.
# This function replaces '(instance)' with a * glob pattern and the (repository)
# with '.authorized_keys'. This allows this script to find all .authorized_keys files associated
# with all MarkUs instances.
#
# For example:
#  echo $(authorized_key_paths)  # /some/path/*/repos/.authorized_keys
authorized_key_paths() {
  local replaced_instance_path="${MARKUS_REPO_LOC_PATTERN//(instance)/*}"
  echo "${replaced_instance_path//(repository)/.authorized_keys}"
}

# shellcheck disable=SC2046
cat $(authorized_key_paths)
