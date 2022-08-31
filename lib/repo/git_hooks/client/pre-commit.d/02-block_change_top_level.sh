#!/usr/bin/env sh

echo '[MarkUs] Checking whether top-level files/directories were created/modified...'

CHANGED_FILES=$(git diff-index --name-only HEAD)

if printf '%s' "$CHANGED_FILES" | grep -qv -e '/' -e '.gitignore'; then
  echo "[MarkUs] Error: Top-level change detected for the following entries:"
  echo "$CHANGED_FILES" | grep -v -e '/' -e '.gitignore'
  echo "[MarkUs] You should unstage this change."
  exit 1
fi
