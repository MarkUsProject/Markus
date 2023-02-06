#!/usr/bin/env sh

CHANGED_FILES=$(git diff --name-only --no-renames --diff-filter=d --staged HEAD) # diff does not include deleted files
MAX_FILE_SIZE=$(git show HEAD:.max_file_size)

echo "$CHANGED_FILES" | while read -r path; do
  test -z "$path" && continue
  sha=$(git ls-files --stage "$(git rev-parse --show-toplevel)/$path" | cut -d' ' -f 2)
  size=$(git cat-file -s "$sha")
  if [ "$size" -gt "$MAX_FILE_SIZE" ]; then
    echo "[MarkUs] Error: The size of the modified file $path exceeds the maximum of $MAX_FILE_SIZE bytes."
    exit 1
  fi
done || exit 1
