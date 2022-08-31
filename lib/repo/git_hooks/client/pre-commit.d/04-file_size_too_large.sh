#!/usr/bin/env sh

CHANGED_FILES=$(git diff --name-status --no-renames --diff-filter=d HEAD) # diff does not include deleted files
MAX_FILE_SIZE=$(git show HEAD:.max_file_size)

# shellcheck disable=SC2034
echo "$CHANGED_FILES" | while read -r _status path; do
  sha=$(git ls-files --stage "$(git rev-parse --show-toplevel)/$path" | cut -d' ' -f 2)
  size=$(git cat-file -s "$sha")
  if [ "$size" -gt "$MAX_FILE_SIZE" ]; then
    echo "[MARKUS] Error: The size of the uploaded file $path exceeds the maximum of $MAX_FILE_SIZE bytes."
    exit 1
  fi
done || exit 1
