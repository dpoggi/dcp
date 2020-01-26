# MetaMan
# cli.sh - command-line interface
#
# Copyright (C) 2017-2020 Dan Poggi
#
# This software may be modified and distributed under the terms
# of the MIT license. See the LICENSE file for details.

__mm_on_usage() {
  cat >&2 <<EOT
Usage: mm_on [options] ${MM_TOOLS_FOR_USAGE} ...

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
        if ! __ary_includes "$1" "${MM_TOOLS[@]}"; then
          printf 'Unknown tool "%s"\n\n' "$1" >&2
          __mm_on_usage
          return 1
        fi
        tools+=("$1")
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
      tools=("${MM_TOOLS[@]}")
    else
      printf 'No tools specified\n\n' >&2
      __mm_on_usage
      return 1
    fi
  fi

  local tool tool_upper exit_status
  local error_flag="false"

  for tool in "${tools[@]}"; do
    tool_upper="$(__strtoupper "${tool}")"

    if [[ "${soft}" = "false" ]]; then
      unset "MM_DISABLE_${tool_upper}"
    fi

    if __is_true "MM_DISABLE_${tool_upper}"; then
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
Usage: mm_off [options] ${MM_TOOLS_FOR_USAGE} ...

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
        if ! __ary_includes "$1" "${MM_TOOLS[@]}"; then
          printf 'Unknown tool "%s"\n\n' "$1" >&2
          __mm_off_usage
          return 1
        fi
        tools+=("$1")
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
      tools=("${MM_TOOLS[@]}")
    else
      printf 'No tools specified\n\n' >&2
      __mm_off_usage
      return 1
    fi
  fi

  local tool tool_upper
  local should_reexec="false"

  for tool in "${tools[@]}"; do
    tool_upper="$(__strtoupper "${tool}")"

    export "MM_DISABLE_${tool_upper}"="true"

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

__mm_only_usage() {
  cat >&2 <<EOT
Usage: mm_only [options] ${MM_TOOLS_FOR_USAGE} ...

OPTIONS:
  -a, --all                                Enable all tools after shell re-exec
  -h, --help                               Display this message
EOT
}

mm_only() {
  local -a tools
  local all_tools="false"

  while (($# > 0)); do
    case "$1" in
      -a|--all)   all_tools="true" ;;
      -h|--help)  __mm_only_usage; return ;;
      -*)
        printf 'Unknown option "%s"\n\n' "$1" >&2
        __mm_only_usage
        return 1
        ;;
      *)
        if ! __ary_includes "$1" "${MM_TOOLS[@]}"; then
          printf 'Unknown tool "%s"\n\n' "$1" >&2
          __mm_only_usage
          return 1
        fi
        tools+=("$1")
    esac

    shift
  done

  if "${all_tools}"; then
    if ((${#tools[@]} == 0)); then
      tools=("${MM_TOOLS[@]}")
    else
      printf 'Explicitly requested tools cannot be combined with -a/--all\n\n' >&2
      __mm_only_usage
      return 1
    fi
  fi

  local tool tool_upper

  for tool in "${MM_TOOLS[@]}"; do
    tool_upper="$(__strtoupper "${tool}")"

    if __ary_includes "${tool}" "${tools[@]}"; then
      __unexport "MM_DISABLE_${tool_upper}"

      if [[ -z "${MM_FORCE_LOAD}" ]]; then
        MM_FORCE_LOAD="${tool}"
      else
        MM_FORCE_LOAD+=" ${tool}"
      fi

      export MM_FORCE_LOAD
    else
      export "MM_DISABLE_${tool_upper}"="true"

      if __is_function "__mm_${tool}_unload" && "__mm_${tool}_is_loaded"; then
        "__mm_${tool}_unload"
      fi
    fi
  done

  eval "${DCP_SHELL_EXEC_CMD[*]}"
}
