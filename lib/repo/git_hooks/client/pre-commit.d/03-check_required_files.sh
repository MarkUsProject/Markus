#!/usr/bin/env sh

CHANGED_FILES=$(git diff-index --name-status --no-renames --cached HEAD)
REQUIREMENTS=$(git show HEAD:.required)
ALL_FILES=$(git ls-files)

echo "$CHANGED_FILES" | while read -r status path; do
  echo "$path" | grep -q '/' || continue # ignore top level changes

  assignment_requirements=$(echo "$REQUIREMENTS" | grep "^${path%/${path#*/}}")

  if [ -z "$assignment_requirements" ]; then
    continue
  fi

  required_files=$(echo "$assignment_requirements" | sed 's/true$\|false$//g')

  case "$status" in
    A)
      if ! echo "$assignment_requirements" | grep -q "^$path"; then
        # The added file is not one of the required files
        if echo "$assignment_requirements" | grep -q 'true$'; then
          # The assignment only allows required files to be submitted
          printf "[MarkUs] Error: You are submitting %s but this assignment only requires:\n\n%s\n" "$path" "$required_files"
          exit 1
        else
          printf "[MarkUs] Warning: You are submitting %s but this assignment only requires:\n\n%s\n" "$path" "$required_files"
        fi
      fi
      ;;
    D)
      if echo "$assignment_requirements" | grep -q "^$path"; then
        # The deleted file is one of the required files
        echo "[MarkUs] Warning: You are deleting required file $path."
      fi
      ;;
    M)
      if ! echo "$assignment_requirements" | grep -q "^$path"; then
        # The modified file is not one of the required files
        if echo "$assignment_requirements" | grep -q 'true$'; then
          # The assignment only allows required files to be submitted
          printf "[MarkUs] Warning: You are modifying non-required file %s but this assignment only requires:\n\n%s\n" "$path" "$required_files"
        fi
      fi
      ;;
    *)
      ;;
  esac
done || exit 1

CHANGED_ASSIGNMENT_PATTERN=$(echo "$CHANGED_FILES" | while read -r status path; do
  printf "^%s|" "${path%/${path#*/}}"
done)

echo "$REQUIREMENTS" | grep "${CHANGED_ASSIGNMENT_PATTERN%?}" | while IFS= read -r line; do
  required_file=${line% *}
  echo "$ALL_FILES" | grep -q "^$required_file$" || echo "[MarkUs] Warning: required file $required_file is missing."
done
