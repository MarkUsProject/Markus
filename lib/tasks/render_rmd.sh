#!/bin/bash
set -euo pipefail

input_file="$1"
output_file="$2"

if [[ ! -f "$input_file" ]]; then
  echo "Error: input file '$input_file' does not exist" >&2
  exit 1
fi

Rscript -e "rmarkdown::render('$input_file', output_file = '$output_file')"
