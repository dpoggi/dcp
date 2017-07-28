# MetaMan
# cli.sh - command-line interface
#
# Copyright (C) 2017 Dan Poggi
#
# This software may be modified and distributed under the terms
# of the MIT license. See the LICENSE file for details.

__mm_on_usage() {
  cat <<EOT
Usage: mm_on [options] ${MM_TOOLS_STR} ...

OPTIONS:
  -a, --all                                              Enable all tools
  -s, --soft                                             Respect disabled flags
  -h, --help                                             Display this message
EOT
}

mm_on() {
  local -a tools
  local all="false"
  local soft="false"

  while (( $# > 0 )); do
    case "$1" in
      -a|--all)   all="true"            ;;
      -s|--soft)  soft="true"           ;;
      -h|--help)  __mm_on_usage; return ;;
      -*)
        printf >&2 "Unknown option %s\n\n" "$1"
        __mm_on_usage >&2
        return 1
        ;;
      *)
        if ! __ary_includes "$1" "${MM_TOOLS[@]}"; then
          printf >&2 "Invalid tool %s\n\n" "$1"
          __mm_on_usage >&2
          return 1
        fi
        tools+=("$1")
    esac
    shift
  done

  if [[ "${all}" = "true" ]]; then
    tools=("${MM_TOOLS[@]}")
  fi

  if [[ "${#tools[@]}" -eq "0" ]]; then
    printf >&2 "Error: no tool specified\n\n"
    __mm_on_usage >&2
    return 1
  fi

  local tool tool_upper exit_status

  for tool in "${tools[@]}"; do
    tool_upper="$(__strtoupper "${tool}")"

    if [[ "${soft}" = "false" ]]; then
      unset "MM_DISABLE_${tool_upper}"
    fi

    if __is_true "MM_DISABLE_${tool_upper}"; then
      continue
    fi

    if "__mm_${tool}_is_loaded"; then
      continue
    fi

    if ! "__mm_${tool}_is_installed"; then
      continue
    fi

    "__mm_${tool}_load"

    if [[ "$?" -ne "0" ]]; then
      printf >&2 "Error: unable to load %s" "${tool}"
      continue
    fi

    if __mm_is_comp_loaded "${tool}"; then
      continue
    fi

    __mm_load_comp "${tool}"
  done
}

__mm_off_usage() {
  cat <<EOT
Usage: mm_off [options] ${MM_TOOLS_STR} ...

OPTIONS:
  -a, --all                                                Disable all tools
  -h, --help                                               Display this message
EOT
}

mm_off() {
  local -a tools
  local all="false"

  while (( $# > 0 )); do
    case "$1" in
      -a|--all)   all="true"              ;;
      -h|--help)  __mm_off_usage; return  ;;
      -*)
        printf >&2 "Unknown option %s\n\n" "$1"
        __mm_off_usage >&2
        return 1
        ;;
      *)
        if ! __ary_includes "$1" "${MM_TOOLS[@]}"; then
          printf >&2 "Invalid tool %s\n\n" "$1"
          __mm_off_usage >&2
          return 1
        fi
        tools+=("$1")
    esac
    shift
  done

  if [[ "${all}" = "true" ]]; then
    tools=("${MM_TOOLS[@]}")
  fi

  if [[ "${#tools[@]}" -eq "0" ]]; then
    printf >&2 "Error: no tool specified\n\n"
    __mm_off_usage >&2
    return 1
  fi

  local tool

  for tool in "${tools[@]}"; do
    export "MM_DISABLE_$(__strtoupper "${tool}")"="true"
  done

  eval "${DCP_SHELL_EXEC_CMD[*]}"
}
