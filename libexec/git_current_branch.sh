#!/bin/sh

set -e

FOR_PS1="false"
while [ "$#" -gt "0" ]; do
  if [ "$1" = "--ps1" ]; then
    FOR_PS1="true"
  fi
  shift
done

CURRENT_BRANCH="$(git branch 2>/dev/null | sed -e '/^[^\*]/d' -e 's/\* \(.*\)/\1/')"
if [ -z "${CURRENT_BRANCH}" ]; then
  if "${FOR_PS1}"; then
    exit
  else
    exit 1
  fi
fi

if "${FOR_PS1}"; then
  printf '(%s)\n' "${CURRENT_BRANCH}"
else
  printf '%s\n' "${CURRENT_BRANCH}"
fi
