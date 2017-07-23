__logf() {
  local lvl="$1"; shift
  local lvl_clr="$1"; shift
  local fmt="$1"; shift

  if [[ -t 1 ]]; then
    printf "\033[2;39;49m%s ${lvl_clr}${lvl}\033[2;39;49m : \033[0m${fmt}" \
           "$(__log_date)" \
           "$@"
  else
    printf "%s ${lvl} : ${fmt}" \
           "$(__log_date)" \
           "$@"
  fi
}

__log_date() { date "+%Y-%m-%d %H:%M:%S"; }

infof() { __logf " INFO" "\033[0;34m" "$@"; }
warnf() { __logf " WARN" "\033[0;33m" "$@"; }
errorf() { __logf "ERROR" "\033[0;31m" "$@"; }

infofln() { infof "$@"; printf "\n"; }
warnfln() { warnf "$@"; printf "\n"; }
errorfln() { errorf "$@"; printf "\n"; }
