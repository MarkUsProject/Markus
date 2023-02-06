#!/usr/bin/env sh

REF_NAME=$1
OLD_COMMIT=$2
NEW_COMMIT=$3

# allow force push to branches other than master
[ "$REF_NAME" = 'refs/heads/master' ] || exit 0

# no need to check at this point if old_commit or new_commit are 0, since master can't be deleted or created.
# forbid commits reachable from old_commit but not from new_commit, i.e. the old tree was replaced.
if [ -n "$(git rev-list "$OLD_COMMIT" "^$NEW_COMMIT")" ]; then
  echo '[MarkUs] Error: forced push is not allowed on master!'
  exit 1
fi
