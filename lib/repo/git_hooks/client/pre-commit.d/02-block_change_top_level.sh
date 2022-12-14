#!/usr/bin/env sh

CHANGED_FILES=$(git diff-index --name-only --cached HEAD)
CURRENT_TOP_LEVEL=$(git ls-tree --name-only --full-tree HEAD)

TOP_LEVEL_CHANGES=$(echo "$CHANGED_FILES" | while read -r entry; do
  top_level=${entry%/${entry#*/}}
  if [ "$top_level" != '.gitignore' ]; then
    if ! echo "$CURRENT_TOP_LEVEL" | grep -q "^${top_level}$" 2> /dev/null || # created
       [ "$top_level" = "$entry" ] || # modified
       [ ! -e "$top_level" ]; then # deleted
      echo "$top_level"
    fi
  fi
done)

if [ -n "$TOP_LEVEL_CHANGES" ]; then
  echo "[MarkUs] Error: Top-level change detected for the following entries:"
  echo "$TOP_LEVEL_CHANGES" | sort | uniq
  echo "[MarkUs] You should unstage this change."
  exit 1
fi
