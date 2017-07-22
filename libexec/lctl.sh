#!/usr/bin/env bash

set -euo pipefail

readonly LAUNCHCTL_PATH="$(type -P launchctl)"

declare -a CMD_PREFIX
declare DOMAIN_TARGET SERVICE_PATH SERVICE_TARGET

. "${HOME}/.dcp/lib/logging.sh"

__filter_output() {
  sed -e '/36: /d'
}

__is_errexit() {
  if [[ " $- " = *e* ]]; then
    printf "true"
  else
    printf "false"
  fi
}

__launchctl() {
  # local was_errexit="$(__is_errexit)"

  set +e

  "${CMD_PREFIX[@]}" "${LAUNCHCTL_PATH}" "$@" 2>&1 | __filter_output

  local exit_status="$?"

  # if [[ "${was_errexit}" = "true" ]]; then
  set -e
  # fi

  case "${exit_status}" in
    36) return ;;
    *)  return "${exit_status}"
  esac
}

__launchctl_log() {
  local verb=""

  case "$1" in
    bootout)    verb="Stopping"   ;;
    bootstrap)  verb="Starting"   ;;
    disable)    verb="Disabling"  ;;
    "enable")   verb="Enabling"   ;;
  esac

  if [[ -n "${verb}" ]]; then
    infofln "%s %s..." "${verb}" "${SERVICE_TARGET}"
  fi
}

launchctl() {
  local action="$1"

  if [[ "${action}" = "bootout" ]] && ! launchctl blame >/dev/null; then
    warnfln "%s not running" "${SERVICE_TARGET}"
    return 1
  elif [[ "${action}" = "bootstrap" ]] && launchctl blame >/dev/null; then
    warnfln "%s already running" "${SERVICE_TARGET}"
    return 1
  fi

  __launchctl_log "${action}"

  case "${action}" in
    blame|bootout|disable|"enable")
      __launchctl "${action}" "${SERVICE_TARGET}"
      ;;
    bootstrap)
      __launchctl "${action}" "${DOMAIN_TARGET}" "${SERVICE_PATH}"
      ;;
  esac
}

launchctl_status() {
  local line=""
  local reason=""
  local exit_status=""

  while IFS='' read -r line || ! exit_status="${line}"; do
    reason="${reason}${line}"
  done < <(set +e; launchctl blame; printf "%s" "$?"; set -e)

  if [[ "${exit_status}" -eq "0" ]]; then
    infofln "%s running. Reason: %s" \
            "${SERVICE_TARGET}" \
            "${reason}"
  else
    infofln "%s not running" "${SERVICE_TARGET}"
  fi
}

__get_domain_target() {
  case "$1" in
    gui|user)
      printf "%s/%s" "$1" "$(id -u)"
      ;;
    *)
      printf "%s" "$1"
  esac
}

__resolve_path() {
  printf "%s/%s" \
         "$(cd "$(dirname "$1")" && pwd -P)" \
         "$(basename "$1")"
}

__get_service_name() {
  /usr/libexec/PlistBuddy -c 'Print :Label' "$1"
}

configure_service() {
  DOMAIN_TARGET="$(__get_domain_target "$1")"
  SERVICE_PATH="$(__resolve_path "$2")"
  SERVICE_TARGET="${DOMAIN_TARGET}/$(__get_service_name "${SERVICE_PATH}")"

  if [[ "${DOMAIN_TARGET}" = */* ]]; then
    CMD_PREFIX=(command)
  else
    CMD_PREFIX=(sudo -H)
  fi

  readonly DOMAIN_TARGET SERVICE_PATH SERVICE_TARGET CMD_PREFIX
}

main() {
  local domain="$1"
  local action="$2"
  local service="$3"

  configure_service "${domain}" "${service}"

  case "${action}" in
    start)    launchctl bootstrap ;;
    stop)     launchctl bootout   ;;
    restart)
      launchctl bootout
      launchctl bootstrap
      ;;
    enable)   launchctl enable    ;;
    disable)  launchctl disable   ;;
    status)   launchctl_status    ;;
    *)        return 1
  esac
}

main "$@"
