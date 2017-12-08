if [[ -t 1 ]]; then
  __logf() {
    local level="$1"; shift
    local level_color="$1"; shift
    local format="$1"; shift
    printf "\033[2;39;49m%s\033[0m ${level_color}${level}\033[0;35;49m %s\033[2;39m : \033[0m${format}" \
           "$(date '+%F %T')" "$$" "$@"
  }
else
  __logf() {
    local level="$1"; shift; shift
    local format="$1"; shift
    printf "%s ${level} %s : ${format}" \
           "$(date '+%F %T')" "$$" "$@"
  }
fi

if [[ " DEBUG INFO WARN ERROR " != *" ${DCP_LOG_LEVEL} "* ]]; then
  DCP_LOG_LEVEL="INFO"
fi
readonly DCP_LOG_LEVEL
export DCP_LOG_LEVEL

if [[ "${DCP_LOG_LEVEL}" = "DEBUG" ]]; then
  debugf() { __logf "DEBUG" "\033[0;32m" "$@"; }
  debugfln() { debugf "$@"; printf "\n"; }
  debugnl() { debugfln ""; }
else
  debugf() { :; }
  debugfln() { :; }
  debugnl() { :; }
fi

if [[ "${DCP_LOG_LEVEL}" = "DEBUG" || "${DCP_LOG_LEVEL}" = "INFO" ]]; then
  infof() { __logf " INFO" "\033[0;34m" "$@"; }
  infofln() { infof "$@"; printf "\n"; }
  infonl() { infofln ""; }
else
  infof() { :; }
  infofln() { :; }
  infonl() { :; }
fi

if [[ "${DCP_LOG_LEVEL}" != "ERROR" ]]; then
  warnf() { __logf " WARN" "\033[0;33m" "$@"; }
  warnfln() { warnf "$@"; printf "\n"; }
  warnnl() { warnfln ""; }
else
  warnf() { :; }
  warnfln() { :; }
  warnnl() { :; }
fi

errorf() { __logf "ERROR" "\033[1;31m" "$@"; }
errorfln() { errorf "$@"; printf "\n"; }
errornl() { errorfln ""; }
