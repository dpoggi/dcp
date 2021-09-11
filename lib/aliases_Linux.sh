#
# Network admin things
#

__net_things() {
  if ! command -v netstat >/dev/null; then
    printf 'netstat not found\n' >&2
    return 1
  fi

  local columns script args=()
  while (($# > 0)); do
    case "$1" in
      -c) columns="$2"; shift ;;
      -s) script="$2"; shift ;;
      -i) args+=(--protocol=inet,inet6) ;;
      -u) args+=(--protocol=unix) ;;
      *)  return 1
    esac
    shift
  done

  local i column separator
  while IFS='' read -d ' ' -r column; do
    if [[ -n "${separator}" ]]; then
      separator+=" "
    fi

    for ((i=0; i < ${#column}; i++)); do
      separator+="="
    done
  done <<<"${columns} "

  local output
  output="$(
    sudo -H netstat -lnpW "${args[@]}" | awk -F '  +' "${script}" | sort -g
  )"

  printf '%s\n%s\n%s\n' "${columns}" "${separator}" "${output}" \
    | column -t -o '    '
}

net_ports() {
  __net_things                                    \
    -i                                            \
    -c "PID Program_Name Protocol Bound_Address"  \
    -s '
      {
        pid_name=""
      }

      $1 ~ /^tcp6?$/ {
        pid_name=$6
      }

      $1 ~ /^udp6?$/ {
        pid_name=$5
      }

      length(pid_name) > 0 {
        sub(/:.*$/, "", pid_name)
        sub("/", " ", pid_name)
        sub(/^0 /, "", $3)

        print pid_name, $1, $3
      }
    '
}

net_sockets() {
  __net_things                        \
    -u                                \
    -c "PID Program_Name Socket_Path" \
    -s '
      $1 == "unix" {
        sub(/:.*$/, "", $7)
        sub("/", " ", $7)

        print $7, $8
      }
    '
}

net_all() {
  net_ports
  printf '\n'
  net_sockets
}
