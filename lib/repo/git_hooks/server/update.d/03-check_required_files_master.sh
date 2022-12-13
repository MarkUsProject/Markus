#!/usr/bin/env sh

REF_NAME=$1
OLD_COMMIT=$2
NEW_COMMIT=$3

# allow top level changes to branches other than master
[ "$REF_NAME" = 'refs/heads/master' ] || exit 0

# allow MarkUs itself to make any changes without error (see config/application.rb)
[ -n "$SKIP_LOCAL_GIT_HOOKS" ] || exit 0

CHANGED_FILES=$(git diff --name-status --no-renames "$OLD_COMMIT" "$NEW_COMMIT")
REQUIREMENTS=$(git show "${OLD_COMMIT}:.required")
ALL_FILES=$(git ls-tree -r --name-only "$NEW_COMMIT")

echo "$CHANGED_FILES" | while read -r status path; do
  echo "$path" | grep -q '/' || continue # ignore top level changes

  assignment_requirements=$(echo "$REQUIREMENTS" | grep "^${path%/${path#*/}}")

  if [ -z "$assignment_requirements" ]; then
    continue
  fi

  required_files=$(echo "$assignment_requirements" | cut -d' ' -f 1)

  case "$status" in
    A)
      if ! echo "$assignment_requirements" | grep -q "$path "; then
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
      if echo "$assignment_requirements" | grep -q "$path "; then
        # The deleted file is one of the required files
        echo "[MarkUs] Warning: You are deleting required file $path."
      fi
      ;;
    M)
      if ! echo "$assignment_requirements" | grep -q "$path "; then
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

CHANGED_ASSIGNMENT_PATTERN=$(echo "$CHANGED_FILES" | while read -r status path; do
  printf "^%s|" "${path%/${path#*/}}"
done)

echo "$REQUIREMENTS" | grep "${CHANGED_ASSIGNMENT_PATTERN%?}" | while IFS= read -r line; do
  required_file=${line% *}
  echo "$ALL_FILES" | grep -q "$required_file" || echo "[MarkUs] Warning: required file $required_file is missing."
done
