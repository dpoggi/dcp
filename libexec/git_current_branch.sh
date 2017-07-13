#!/usr/bin/env bash

set -euo pipefail

readonly CURRENT_BRANCH="$(git branch 2> /dev/null | sed -e '/^[^\*]/d' -e 's/\* \(.*\)/\1/')"

if [[ -z "${CURRENT_BRANCH}" ]]; then
  exit
fi

if [[ " $* " = *\ --ps1\ * ]]; then
  printf "(%s)" "${CURRENT_BRANCH}"
else
  printf "%s" "${CURRENT_BRANCH}"
fi
