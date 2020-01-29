# MetaMan
# cli.sh - command-line interface
#
# Copyright (C) 2017-2020 Dan Poggi
#
# This software may be modified and distributed under the terms
# of the MIT license. See the LICENSE file for details.

__mm_on_usage() {
  cat >&2 <<EOT
Usage: mm_on [options] [${__mm_usage_tools}]...

OPTIONS:
  -a, --all                                              Enable all tools
  -s, --soft                                             Respect disabled flags
  -h, --help                                             Display this message
EOT
}

mm_on() {
  local -a tools
  local all_tools="false" soft="false"

  while (($# > 0)); do
    case "$1" in
      -a|--all)   all_tools="true" ;;
      -s|--soft)  soft="true" ;;
      -h|--help)  __mm_on_usage; return ;;
      -*)
        printf 'Unknown option "%s"\n\n' "$1" >&2
        __mm_on_usage
        return 1
        ;;
      *)
        if ! __ary_includes "$1" "${__mm_tools[@]}"; then
          printf 'Unknown tool "%s"\n\n' "$1" >&2
          __mm_on_usage
          return 1
        fi
        tools+=( "$1" )
    esac

    shift
  done

  if ((${#tools[@]} > 0)); then
    if "${all_tools}"; then
      printf 'Explicitly requested tools cannot be combined with -a/--all\n\n' >&2
      __mm_on_usage
      return 1
    fi
  else
    if "${all_tools}"; then
      tools=("${__mm_tools[@]}")
    else
      printf 'No tools specified\n\n' >&2
      __mm_on_usage
      return 1
    fi
  fi

  local tool exit_status
  local error_flag="false"

  for tool in "${tools[@]}"; do
    if [[ "${soft}" = "false" ]]; then
      unset "__mm_disable_${tool}"
    fi

    if __is_true "__mm_disable_${tool}"; then
      continue
    fi

    if "__mm_${tool}_is_loaded" && [[ "${tool}" != "cargo" ]]; then
      continue
    fi

    if ! "__mm_${tool}_is_installed"; then
      if ! "${all_tools}"; then
        printf '%s is not installed' "${tool}" >&2
        error_flag="true"
      fi

      continue
    fi

    "__mm_${tool}_load"
    exit_status="$?"

    if ((exit_status != 0)); then
      printf 'Unable to load %s' "${tool}" >&2
      error_flag="true"
      continue
    fi

    if ! __mm_is_comp_loaded "${tool}"; then
      __mm_load_comp "${tool}"
    fi
  done

  if "${error_flag}"; then
    return 1
  fi
}

__mm_off_usage() {
  cat >&2 <<EOT
Usage: mm_off [options] [${__mm_usage_tools}]...

OPTIONS:
  -a, --all                                                Disable all tools
  -h, --help                                               Display this message
EOT
}

mm_off() {
  local -a tools
  local all_tools="false"

  while (($# > 0)); do
    case "$1" in
      -a|--all)   all_tools="true" ;;
      -h|--help)  __mm_off_usage; return ;;
      -*)
        printf 'Unknown option "%s"\n\n' "$1" >&2
        __mm_off_usage
        return 1
        ;;
      *)
        if ! __ary_includes "$1" "${__mm_tools[@]}"; then
          printf 'Unknown tool "%s"\n\n' "$1" >&2
          __mm_off_usage
          return 1
        fi
        tools+=( "$1" )
    esac

    shift
  done

  if ((${#tools[@]} > 0)); then
    if "${all_tools}"; then
      printf 'Explicitly requested tools cannot be combined with -a/--all\n\n' >&2
      __mm_off_usage
      return 1
    fi
  else
    if "${all_tools}"; then
      tools=("${__mm_tools[@]}")
    else
      printf 'No tools specified\n\n' >&2
      __mm_off_usage
      return 1
    fi
  fi

  local tool
  local should_reexec="false"

  for tool in "${tools[@]}"; do
    export "__mm_disable_${tool}"="true"

    if __is_function "__mm_${tool}_unload"; then
      if "__mm_${tool}_is_loaded"; then
        "__mm_${tool}_unload"
      fi
    else
      should_reexec="true"
    fi
  done

  if "${should_reexec}"; then
    eval "${DCP_SHELL_EXEC_CMD[*]}"
  fi
}

__mm_just_usage() {
  cat >&2 <<EOT
Usage: mm_just [options] [${__mm_usage_tools}]...

OPTIONS:
  -a, --all                                Enable all tools after shell re-exec
  -h, --help                               Display this message
EOT
}

mm_just() {
  local -a tools
  local all_tools="false"

  while (($# > 0)); do
    case "$1" in
      -a|--all)   all_tools="true" ;;
      -h|--help)  __mm_just_usage; return ;;
      -*)
        printf 'Unknown option "%s"\n\n' "$1" >&2
        __mm_just_usage
        return 1
        ;;
      *)
        if ! __ary_includes "$1" "${__mm_tools[@]}"; then
          printf 'Unknown tool "%s"\n\n' "$1" >&2
          __mm_just_usage
          return 1
        fi
        tools+=( "$1" )
    esac

    shift
  done

  if "${all_tools}"; then
    if ((${#tools[@]} == 0)); then
      tools=("${__mm_tools[@]}")
    else
      printf 'Explicitly requested tools cannot be combined with -a/--all\n\n' >&2
      __mm_just_usage
      return 1
    fi
  fi

  local tool

  for tool in "${__mm_tools[@]}"; do
    if __ary_includes "${tool}" "${tools[@]}"; then
      __unexport "__mm_disable_${tool}"

      if [[ -z "${__mm_force_load}" ]]; then
        __mm_force_load="${tool}"
      else
        __mm_force_load+=" ${tool}"
      fi

      export __mm_force_load
    else
      export "__mm_disable_${tool}"="true"

      if __is_function "__mm_${tool}_unload" && "__mm_${tool}_is_loaded"; then
        "__mm_${tool}_unload"
      fi
    fi
  done

  eval "${DCP_SHELL_EXEC_CMD[*]}"
}
