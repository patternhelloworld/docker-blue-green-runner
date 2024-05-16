#!/bin/bash
set -eu

git config apply.whitespace nowarn
git config core.filemode false

validate_file_size() {
  local input="$1"

  if [[ $input =~ ^[0-9]+[kKmM]$ ]]; then
    echo "true"
  else
    echo "false"
  fi
}

validate_number() {
  local input="$1"

  if [[ $input =~ ^[0-9]+$ ]]; then
    echo "true"
  else
    echo "false"
  fi
}