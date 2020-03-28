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

declare -rx DCP_LOG_COLOR DCP_LOG_LEVEL

if { printf '' >&3; } 2>/dev/null; then
  __dcp_printf() { printf "$@" >&3; }
else
  __dcp_printf() { printf "$@" >&2; }
fi

if [[ "${DCP_LOG_COLOR}" = "always" ]] || [[ "${DCP_LOG_COLOR}" = "auto" && -t 2 ]]; then
  __dcp_logf() {
    local level="$1"; shift
    local level_color="$1"; shift
    local format="$1"; shift

    __dcp_printf "\\033[2;39;49m%s %b%s \\033[0;35m%s \\033[2;39m: \\033[0m${format}" \
                 "$(date '+%F %T')" "${level_color}" "${level}" "$$" "$@"
  }

  __dcp_log_cmd() {
    local first="$1"; shift

    __dcp_printf '\033[2;39;49m+ \033[0;35m%s\033[0m' "${first}"
    __dcp_printf '%s' "${@/#/ }"
    __dcp_printf '\n'
  }
else
  __dcp_logf() {
    local level="$1"; shift; shift
    local format="$1"; shift

    __dcp_printf "%s [%s] %s : ${format}" \
                 "$(date '+%F %T')" "${level}" "$$" "$@"
  }

  __dcp_log_cmd() {
    local first="$1"; shift

    __dcp_printf '+ %s' "${first}"
    __dcp_printf '%s' "${@/#/ }"
    __dcp_printf '\n'
  }
fi

if __dcp_contains "${DCP_LOG_LEVEL}" debug; then
  debugf() { __dcp_logf "DEBUG" '\033[0;32m' "$@"; }
  debugfln() { debugf "$@"; __dcp_printf '\n'; }
else
  debugf() { :; }
  debugfln() { :; }
fi

if __dcp_contains "${DCP_LOG_LEVEL}" debug info; then
  infof() { __dcp_logf " INFO" '\033[0;34m' "$@"; }
  infofln() { infof "$@"; __dcp_printf '\n'; }
else
  infof() { :; }
  infofln() { :; }
fi

if __dcp_contains "${DCP_LOG_LEVEL}" debug info warn; then
  warnf() { __dcp_logf " WARN" '\033[0;33m' "$@"; }
  warnfln() { warnf "$@"; __dcp_printf '\n'; }
else
  warnf() { :; }
  warnfln() { :; }
fi

if __dcp_contains "${DCP_LOG_LEVEL}" debug info warn error; then
  errorf() { __dcp_logf "ERROR" '\033[0;31m' "$@"; }
  errorfln() { errorf "$@"; __dcp_printf '\n'; }
else
  errorf() { :; }
  errorfln() { :; }
fi

log_cmd() {
  (($# > 0)) || return

  local arg cmd=() quote="'\\''"
  for arg in "$@"; do
    [[ "${arg}" =~ [!{}\`\'\"\ \\] ]] &&
      cmd+=("'${arg//\'/${quote}}'") ||
      cmd+=("${arg}")
  done

  __dcp_log_cmd "${cmd[@]}"

  "$@"
}

unset -f __dcp_contains
