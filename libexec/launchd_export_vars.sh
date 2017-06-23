#!/usr/bin/env bash

set -euo pipefail

readonly ENV_SCRIPT_PATH="${HOME}/.dcp/localenv"
readonly CONFIG_PATH="${XDG_CONFIG_HOME:-${HOME}/.config}/dcp/launchd_vars.lst"

if [[ "$(uname -s)" != "Darwin" ]]; then
  exit 1
fi

if [[ ! -s "${ENV_SCRIPT_PATH}" || ! -s "${CONFIG_PATH}" ]]; then
  exit 1
fi

. "${ENV_SCRIPT_PATH}"

while read -r var_name; do
  launchctl setenv "${var_name}" "${!var_name}" || true
done < <(cat "${CONFIG_PATH}")
