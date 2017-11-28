#!/bin/bash

set -eo pipefail

readonly ENV_SCRIPT_PATH="${DCP:-${HOME}/.dcp}/localenv"
readonly CONFIG_PATH="${XDG_CONFIG_HOME:-${HOME}/.config}/dcp/launchd_vars.lst"

logfln() {
  local format="$1"; shift
  printf >&2 "[%s] ${format}\n" "$(date '+%F %T')" "$@"
}

check_uname() {
  if [[ "$(uname -s)" != "$1" ]]; then
    logfln "\`uname -s\` does not return %s" "$1"
    return 1
  fi
}

check_readable() {
  while (( $# > 0 )); do
    if [[ ! -r "$1" ]]; then
      logfln "%s is not readable" "$1"
      return 1
    fi
    shift
  done
}

launchd_set() {
  if launchctl setenv "$1" "${!1}"; then
    logfln "%s set via launchd" "$1"
  else
    logfln "%s could not be set via launchd" "$1"
  fi
}

launchd_unset() {
  if launchctl unsetenv "$1"; then
    logfln "%s was not set, unset via launchd" "$1"
  else
    logfln "%s was not set, but could not be unset via launchd" "$1"
  fi
}

main() {
  check_uname Darwin
  check_readable "${ENV_SCRIPT_PATH}" "${CONFIG_PATH}"

  . "${ENV_SCRIPT_PATH}"

  local var_name
  while IFS='' read -r var_name; do
    if [[ "${!var_name+x}" = "x" ]]; then
      launchd_set "${var_name}"
    else
      launchd_unset "${var_name}"
    fi
  done < <(sed -e '/^[[:space:]]*$/d' "${CONFIG_PATH}")
}

main "$@"
