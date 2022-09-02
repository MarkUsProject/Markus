#!/usr/bin/env bash

# This script finds all .authorized_keys lines associated with markus instances
# from each instance's database and writes their content to stdout.
# This file should be called by the ssh daemon's AuthorizedKeysCommand.

HOME_DIR=${1:-${HOME}}

while IFS= read -r service; do
  psql service="${service}" -qtA -c 'SELECT get_authorized_keys()'
done < <(sed -n "s/^\[\(.*\)\]\s*$/\1/p" "${HOME_DIR}/.pg_service.conf")

# DEPRECATION WARNING: The rest of this file checks for authorized keys in files not from the database.
#                      Writing keys to files is no longer supported. However, the following code is included
#                      so that older versions of MarkUs that do support writing keys to files can be supported as well.
#                      This functionality will be removed in the future.

# shellcheck disable=SC1090
source "${HOME_DIR}/.ssh/rc"

# The MARKUS_REPO_LOC_PATTERN environment variable must be set
#
# It is highly recommended that the MARKUS_REPO_LOC_PATTERN variable sourced from the "${HOME}/.ssh/rc"
# file (see above). You may also hard-code it in this file directly if you wish or source them from another
# file. If you do either, you must modify this file accordingly.
[[ -z ${MARKUS_REPO_LOC_PATTERN} ]] && exit 0

# Convert the MARKUS_REPO_LOC_PATTERN to an actual path that points to a repository on disk.
# This function replaces '(instance)' with a * glob pattern and then appends '.authorized_keys'.
# This allows this script to find all .authorized_keys files associated
# with all MarkUs instances.
#
# For example:
#  echo $(authorized_key_paths)  # /some/path/*/repos/.authorized_keys
authorized_key_paths() {
  echo "${MARKUS_REPO_LOC_PATTERN//(instance)/*}/.authorized_keys"
}

# shellcheck disable=SC2046
cat $(authorized_key_paths) 2> /dev/null

exit 0 # always exit nicely in case some of the authorized keys paths don't exists
