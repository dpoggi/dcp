#!/usr/bin/env bash

set -eo pipefail

if [[ " $* " = *" --ps1 "* ]]; then
  FOR_PS1="true"
else
  FOR_PS1="false"
fi

CURRENT_BRANCH="$(git branch 2>/dev/null | sed -e '/^[^\*]/d' -e 's/\* \(.*\)/\1/')"
if [[ -z "${CURRENT_BRANCH}" ]]; then
  "${FOR_PS1}" && exit || exit 1
fi

if "${FOR_PS1}"; then
  printf '(%s)\n' "${CURRENT_BRANCH}"
else
  printf '%s\n' "${CURRENT_BRANCH}"
fi
