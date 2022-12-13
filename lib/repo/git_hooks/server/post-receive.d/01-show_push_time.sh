#!/usr/bin/env sh

# Do not show time if no change have been made to the master branch
cat - | cut -d' ' -f 3 | grep -qw 'refs/heads/master' || exit 0

echo "[MarkUs] Your submission has been received: $(git reflog -n 1 --date=local --format=format:%gd master)"
