#!/usr/bin/env sh

CHANGED_FILES=$(git diff-index --name-status --no-renames HEAD)
REQUIREMENTS=$(git show HEAD:.required)
ALL_FILES=$(git ls-files)

echo "$CHANGED_FILES" | while read -r status path; do
  echo "$path" | grep -q '/' || continue # ignore top level changes

  assignment_requirements=$(echo "$REQUIREMENTS" | grep "^${path%/*}")
  required_files=$(echo "$assignment_requirements" | cut -d' ' -f 1)

  case "$status" in
    A)
      if ! echo "$REQUIREMENTS" | grep -q "$path "; then
        # The added file is not one of the required files
        if echo "$assignment_requirements" | cut -d' ' -f 2 | grep -q true; then
          # The assignment only allows required files to be submitted
          printf "[MarkUs] Error: You are submitting %s but this assignment only requires:\n\n%s\n" "$path" "$required_files"
          exit 1
        else
          printf "[MarkUs] Warning: You are submitting %s but this assignment only requires:\n\n%s\n" "$path" "$required_files"
        fi
      fi
      ;;
    D)
      if echo "$REQUIREMENTS" | grep -q "$path "; then
        # The deleted file is one of the required files
        echo "[MarkUs] Warning: You are deleting required file $path."
      fi
      ;;
    M)
      if ! echo "$REQUIREMENTS" | grep -q "$path "; then
        # The modified file is not one of the required files
        if echo "$assignment_requirements" | cut -d' ' -f 2 | grep -q true; then
          # The assignment only allows required files to be submitted
          printf "[MarkUs] Warning: You are modifying non-required file %s but this assignment only requires:\n\n%s\n" "$path" "$required_files"
        fi
      fi
      ;;
    *)
      ;;
  esac
done || exit 1


echo "$REQUIREMENTS" | while IFS= read -r line; do
  required_file=${line% *}
  echo "$ALL_FILES" | grep -q "$required_file" || echo "[MarkUs] Warning: required file $required_file is missing."
done
