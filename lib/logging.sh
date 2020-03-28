__dcp_contains() {
  local search="$1"; shift

  while (($# > 0)); do
    [[ "$1" = "${search}" ]] && return || shift
  done

  return 1
}

declare DCP_LOG_COLOR DCP_LOG_LEVEL >/dev/null

if ! __dcp_contains "${DCP_LOG_COLOR}" always auto never; then
  DCP_LOG_COLOR="auto"
fi
if ! __dcp_contains "${DCP_LOG_LEVEL}" debug info warn error hush none off quiet silent; then
  DCP_LOG_LEVEL="info"
fi

if { printf '' >&3; } 2>/dev/null; then
  __dcp_printf() { printf "$@" >&3; }
  __dcp_printf_isatty() { [[ -t 3 ]]; }
else
  __dcp_printf() { printf "$@" >&2; }
  __dcp_printf_isatty() { [[ -t 2 ]]; }
fi

if [[ "${DCP_LOG_COLOR}" = "always" ]] || { [[ "${DCP_LOG_COLOR}" = "auto" ]] && __dcp_printf_isatty; }; then
  __dcp_log() {
    local level="$1"; shift
    local level_color="$1"; shift
    local format="$1"; shift

    __dcp_printf '\033[2;39;49m%s %b%s \033[0;35m%s \033[2;39m: \033[0m'"${format}"'\n' \
                 "$(date '+%F %T')" "${level_color}" "${level}" "$$" "$@"
  }

  __dcp_log_cmd_name() {
    __dcp_printf '\033[2;39;49m+ \033[0;36m%s\033[0m' "$1"
  }
else
  __dcp_log() {
    local level="$1"; shift; shift
    local format="$1"; shift

    __dcp_printf '%s [%s] %s : '"${format}"'\n' \
                 "$(date '+%F %T')" "${level}" "$$" "$@"
  }

  __dcp_log_cmd_name() {
    __dcp_printf '+ %s' "$1"
  }
fi

if __dcp_contains "${DCP_LOG_LEVEL}" debug; then
  log_debug() { __dcp_log "DEBUG" '\033[0;32m' "$@"; }
else
  log_debug() { :; }
fi
if __dcp_contains "${DCP_LOG_LEVEL}" debug info; then
  log_info() { __dcp_log " INFO" '\033[0;34m' "$@"; }
else
  log_info() { :; }
fi
if __dcp_contains "${DCP_LOG_LEVEL}" debug info warn; then
  log_warn() { __dcp_log " WARN" '\033[0;33m' "$@"; }
else
  log_warn() { :; }
fi
if __dcp_contains "${DCP_LOG_LEVEL}" debug info warn error; then
  log_error() { __dcp_log "ERROR" '\033[0;31m' "$@"; }
else
  log_error() { :; }
fi

log_cmd() {
  [[ -z "$1" ]] && return || :

  local arg cmd_name args=() quote="'\\''"
  for arg in "$@"; do
    if [[ "${arg}" =~ [!%\$\*\|\\[:space:]] || "${arg}" =~ [\`\'\"\(\)\[\]\<\>{}] ]]; then
      arg="'${arg//\'/${quote}}'"
    fi

    if [[ -z "${cmd_name}" ]]; then
      cmd_name="${arg}"
    else
      args+=("${arg}")
    fi
  done

  __dcp_log_cmd_name "${cmd_name}"
  __dcp_printf '%s' "${args[@]/#/ }"
  __dcp_printf '\n'

  "$@"
}

unset -f __dcp_contains __dcp_printf_isatty
