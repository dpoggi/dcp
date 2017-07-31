#!/usr/bin/env bash

set -eo pipefail

readonly LAUNCHCTL_PATH="$(type -P launchctl)"

declare -a CMD_PREFIX
declare DOMAIN_TARGET SERVICE_PATH SERVICE_TARGET

. "${HOME}/.dcp/lib/logging.sh"

__filter_output() {
  sed -e '/36: /d'
}

__launchctl() {
  local was_errexit

  case " $- " in
      *e*) was_errexit="true"   ;;
      *)   was_errexit="false"
  esac

  set +e

  "${CMD_PREFIX[@]}" "${LAUNCHCTL_PATH}" "$@" 2>&1 | __filter_output

  local exit_status="$?"

  if "${was_errexit}"; then
    set -e
  fi

  case "${exit_status}" in
    36) return ;;
    *)  return "${exit_status}"
  esac
}

__log_launchctl_action() {
  local verb

  case "$1" in
    bootout)    verb="Stopping"   ;;
    bootstrap)  verb="Starting"   ;;
    disable)    verb="Disabling"  ;;
    "enable")   verb="Enabling"   ;;
  esac

  if [[ -n "${verb}" ]]; then
    infofln "%s %s ..." "${verb}" "${SERVICE_TARGET}"
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

  __log_launchctl_action "${action}"

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
  local line reason exit_status

  while IFS='' read -r line || ! exit_status="${line}"; do
    reason+="${line}"
  done < <(set +e; launchctl blame; printf "%s" "$?"; set -e)

  local service_status

  case "${exit_status}" in
      0) service_status="Running" ;;
      *) service_status="Stopped"
  esac

  infofln "%s" "${SERVICE_TARGET}"
  infofln "%s" "$(seq -f '-' -s '' 1 "${#SERVICE_TARGET}")"
  infofln "Status: %s" "${service_status}"
  infofln "Reason: %s" "${reason}"
}

__get_domain_target() {
  case "$1" in
    gui|user) printf "%s/%s" "$1" "$(id -u)" ;;
    *)        printf "%s" "$1"
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
