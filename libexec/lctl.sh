#!/usr/bin/env bash

set -eo pipefail

. "${HOME}/.dcp/lib/logging.sh"

readonly LAUNCHCTL_PATH="$(command -v launchctl)"

declare BOOTOUT DOMAIN_TARGET SERVICE_PATH SERVICE_TARGET
declare -a CMD_PREFIX

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
    stop)       verb="Stopping"     ;;
    bootstrap)  verb="Starting"     ;;
    disable)    verb="Disabling"    ;;
    enable)     verb="Enabling"     ;;
    kickstart)  verb="Kickstarting" ;;
  esac

  if [[ -n "${verb}" ]]; then
    infofln "%s %s ..." "${verb}" "${SERVICE_TARGET}"
  fi
}

launchctl() {
  local action="$1"

  case "${action}" in
    stop|kickstart)
      if ! launchctl blame >/dev/null; then
        warnfln "%s is not running" "${SERVICE_TARGET}"
        return 1
      fi
      ;;
    bootstrap)
      if launchctl blame >/dev/null; then
        warnfln "%s is already running" "${SERVICE_TARGET}"
        return 1
      fi
      ;;
  esac

  __log_launchctl_action "${action}"

  case "${action}" in
    stop)
      if "${BOOTOUT}"; then
        __launchctl bootout "${SERVICE_TARGET}"
      else
        __launchctl unload -F "${SERVICE_PATH}"
      fi
      ;;
    bootstrap)
      __launchctl "${action}" "${DOMAIN_TARGET}" "${SERVICE_PATH}"
      ;;
    blame|disable|enable)
      __launchctl "${action}" "${SERVICE_TARGET}"
      ;;
    kickstart)
      __launchctl kickstart -k "${SERVICE_TARGET}"
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
  infofln "%s" "$(seq -f '=' -s '' 1 "${#SERVICE_TARGET}")"
  infofln "Status: %s" "${service_status}"
  infofln "Reason: %s" "${reason}"
}

__get_macos_version() {
  /usr/bin/sw_vers -productVersion | command cut -d '.' -f 2
}

__is_domain_target_global() { [[ "$1" != gui* && "$1" != user* ]]; }

__get_domain_target() {
  if __is_domain_target_global "$1"; then
    printf "%s" "$1"
  else
    printf "%s/%s" "$1" "$(id -u)"
  fi
}

__get_service_name() {
  /usr/libexec/PlistBuddy -c 'Print :Label' "$1"
}

configure_service() {
  if [[ "$(__get_macos_version)" -ge "11" ]]; then
    BOOTOUT="true"
  else
    BOOTOUT="false"
  fi

  DOMAIN_TARGET="$(__get_domain_target "$1")"
  SERVICE_PATH="$(realpath -q "$2")"
  SERVICE_TARGET="${DOMAIN_TARGET}/$(__get_service_name "${SERVICE_PATH}")"

  if __is_domain_target_global "${DOMAIN_TARGET}"; then
    CMD_PREFIX=(sudo -H)
  else
    CMD_PREFIX=(command)
  fi

  readonly BOOTOUT DOMAIN_TARGET SERVICE_PATH SERVICE_TARGET CMD_PREFIX
}

main() {
  local domain="$1"
  local action="$2"
  local service_path="$3"

  configure_service "${domain}" "${service_path}"

  case "${action}" in
    stop)       launchctl stop      ;;
    start)      launchctl bootstrap ;;
    restart)
      launchctl stop
      launchctl bootstrap
      ;;
    disable)    launchctl disable   ;;
    enable)     launchctl enable    ;;
    kickstart)  launchctl kickstart ;;
    status)     launchctl_status    ;;
    *)          return 1
  esac
}

main "$@"
