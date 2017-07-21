__logfln() {
  local lvl="$1"; shift
  local lvl_clr="$1"; shift
  local fmt="$1"; shift

  if [[ -t 1 ]]; then
    printf "\033[2;39;49m%s ${lvl_clr}${lvl}\033[2;39;49m : \033[0m${fmt}\n" \
           "$(__log_date)" \
           "$@"
  else
    printf "%s ${lvl} : ${fmt}\n" \
           "$(__log_date)" \
           "$@"
  fi
}

__log_date() { date "+%Y-%m-%d %H:%M:%S"; }

infofln() { __logfln " INFO" "\033[0;34m" "$@"; }
warnfln() { __logfln " WARN" "\033[0;33m" "$@"; }
errorfln() { __logfln "ERROR" "\033[0;31m" "$@"; }
