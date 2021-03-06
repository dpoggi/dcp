#!/bin/bash

set -eo pipefail

exec 3>&2

. "${HOME}/.dcp/lib/logging.sh"

readonly LAUNCHCTL="$(command -v launchctl)"

declare BOOTOUT WRAPPER DOMAIN_TARGET SERVICE_PATH SERVICE_TARGET
declare -a PREFIX

__filter_stdout() { sed -e '/36: /d'; }

__get_errexit_flag() {
  case " $- " in
    *e*)  printf "true";;
    *)    printf "false"
  esac
}

__launchctl() {
  local was_errexit="$(__get_errexit_flag)"

  if "${was_errexit}"; then set +e; fi

  "${PREFIX[@]}" "${LAUNCHCTL}" "$@" 2>&1 | __filter_stdout
  local exit_status="$?"

  if "${was_errexit}"; then set -e; fi

  case "${exit_status}" in
    36) return;;
  esac

  return "${exit_status}"
}

__log_action() {
  local participle
  case "$1" in
    stop)       participle="Stopping";;
    bootstrap)  participle="Starting";;
    disable)    participle="Disabling";;
    enable)     participle="Enabling";;
    kickstart)  participle="Kickstarting";;
  esac

  if [[ -n "${participle}" ]]; then
    log_info "%s %s ..." "${participle}" "${SERVICE_TARGET}"
  fi
}

launchctl() {
  local action="$1"

  if [[ "${action}" = "stop" ]]; then
    if ! launchctl blame >/dev/null; then
      log_warn "%s is not running" "${SERVICE_TARGET}"
      return 1
    fi
  elif [[ "${action}" = "bootstrap" ]]; then
    if launchctl blame >/dev/null; then
      log_warn "%s is already running" "${SERVICE_TARGET}"
      return 1
    fi
  fi

  __log_action "${action}"

  case "${action}" in
    bootstrap)            __launchctl "${action}" "${DOMAIN_TARGET}" "${SERVICE_PATH}";;
    stop)
      if "${BOOTOUT}"; then
        __launchctl bootout "${SERVICE_TARGET}"
      else
        __launchctl unload -F "${SERVICE_PATH}"
      fi
      ;;
    kickstart)            __launchctl kickstart -k "${SERVICE_TARGET}";;
    blame|enable|disable) __launchctl "${action}" "${SERVICE_TARGET}";;
  esac
}

launchctl_status() {
  local line reason exit_status

  while IFS='' read -r line || ! exit_status="${line}"; do
    reason+="${line}"
  done < <(
    set +e
    launchctl blame
    printf "%s" "$?"
    set -e
  )

  local service_status
  case "${exit_status}" in
      0)  service_status="Running";;
      *)  service_status="Stopped"
  esac

  log_info "%s" "${SERVICE_TARGET}"
  log_info "%s" "$(seq -f '=' -s '' 1 "${#SERVICE_TARGET}")"
  log_info "Status: %s" "${service_status}"
  log_info "Reason: %s" "${reason}"
}

__is_domain_target_global() { [[ "$1" != gui* && "$1" != user* ]]; }

__get_domain_target() {
  if __is_domain_target_global "$1"; then
    printf "%s" "$1"
  else
    printf "%s/%s" "$1" "$(id -u)"
  fi
}

__get_service_label() { /usr/libexec/PlistBuddy -c 'Print :Label' "$1" 2>/dev/null; }

configure_service() {
  local macos_version="$(sw_vers -productVersion | cut -d '.' -f 2)"
  if ((${macos_version} >= 11)); then
    BOOTOUT="true"
  else
    BOOTOUT="false"
  fi

  WRAPPER="$1"
  DOMAIN_TARGET="$(__get_domain_target "$2")"

  SERVICE_PATH="$(cd "$(dirname "$3")" && pwd -P)/$(basename "$3")"
  if [[ ! -s "${SERVICE_PATH}" ]]; then
    return 1
  fi

  SERVICE_TARGET="${DOMAIN_TARGET}/$(__get_service_label "${SERVICE_PATH}")"

  if __is_domain_target_global "${DOMAIN_TARGET}"; then
    PREFIX=(sudo -H)
  fi

  readonly BOOTOUT WRAPPER DOMAIN_TARGET SERVICE_PATH SERVICE_TARGET PREFIX
}

print_usage() {
  cat <<EOT
Usage: ${WRAPPER} (help|status|start|stop|restart|kickstart|enable|disable)
EOT
}

main() {
  local wrapper="$1" domain="$2" service_path="$3"
  local action="$4"

  configure_service "${wrapper}" "${domain}" "${service_path}"

  case "${action}" in
    help)       print_usage; return;;
    status)     launchctl_status;;
    start)      launchctl bootstrap;;
    stop)       launchctl stop;;
    restart)    launchctl stop; launchctl bootstrap;;
    kickstart)  launchctl kickstart;;
    enable)     launchctl enable;;
    disable)    launchctl disable;;
    unstoppable)
      log_error "%s cannot be stopped" "${SERVICE_TARGET}"
      return 1
      ;;
    *)
      log_error "'%s' is not a valid action\n" "${action}"
      print_usage >&3
      return 1
  esac
}

main "$@"
