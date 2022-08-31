#!/usr/bin/env sh

REF_NAME=$1
OLD_COMMIT=$2
NEW_COMMIT=$3

# allow top level changes to branches other than master
[ "$REF_NAME" = 'refs/heads/master' ] || exit 0

# allow MarkUs itself to make top level changes (see config/application.rb)
[ -n "$SKIP_LOCAL_GIT_HOOKS" ] || exit 0

OLD_LS=$(git ls-tree --full-tree --name-only "$OLD_COMMIT")
NEW_LS=$(git ls-tree --full-tree --name-only "$NEW_COMMIT")

# do not allow creating/deleting top level files
TOP_LEVEL_CHANGES=$(printf "%s\n%s\n" "$OLD_LS" "$NEW_LS" | sort | uniq -u)

if printf '%s' "$TOP_LEVEL_CHANGES" | grep -qv -e '/' -e '.gitignore'; then
  echo "[MARKUS] Error: creating/deleting top level files and directories is not allowed on master!"
  exit 1
fi

# do not allow modifying top level files
TOP_LEVEL_MODS=$(git diff --name-only --no-renames "$OLD_COMMIT" "$NEW_COMMIT")

if printf '%s' "$TOP_LEVEL_MODS" | grep -qv -e '/' -e '.gitignore'; then
  echo "[MARKUS] Error: modifying top level files and directories is not allowed on master!"
  exit 1
fi
