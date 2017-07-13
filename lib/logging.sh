__log_date() {
  date "+%Y-%m-%d %H:%M:%S"
}

if [[ -t 1 ]]; then
  __logfln() {
    local lvl="$1"; shift
    local lvl_clr="$2"; shift
    local fmt="$3"; shift

    printf "\033[2;39;49m%s ${lvl_clr}${lvl}\033[2;39;49m : \033[0m${fmt}\n" \
           "$(__log_date)" \
           "$@"
  }
else
  __logfln() {
    local lvl="$1"; shift; shift
    local fmt="$3"; shift

    printf "%s ${lvl} : ${fmt}\n" \
           "$(__log_date)" \
           "$@"
  }
fi

infofln() {
  __logfln " INFO" "\033[0;34m" "$@"
}

warnfln() {
  __logfln " WARN" "\033[0;33m" "$@"
}

errorfln() {
  __logfln "ERROR" "\033[0;31m" "$@"
}
