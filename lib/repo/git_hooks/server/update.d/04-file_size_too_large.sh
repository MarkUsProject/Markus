#!/usr/bin/env sh

OLD_COMMIT=$2
NEW_COMMIT=$3

CHANGED_FILES=$(git rev-list --objects "${OLD_COMMIT}..${NEW_COMMIT}")
MAX_FILE_SIZE=$(git show HEAD:.max_file_size)

echo "$CHANGED_FILES" | while read -r sha path; do
  type=$(git cat-file -t "$sha")
  [ "$type" = 'blob' ] || continue
  size=$(git cat-file -s "$sha")
  if [ "$size" -gt "$MAX_FILE_SIZE" ]; then
    echo "[MARKUS] Error: The size of the uploaded file $path exceeds the maximum of $MAX_FILE_SIZE bytes."
    exit 1
  fi
done || exit 1
