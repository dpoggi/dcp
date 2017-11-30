#
# __valueof: dereference a variable by name
#
# __typeof: prints the type of command the given name is hashed as
#

if [[ "${DCP_SHELL}" = "zsh" ]]; then
  __valueof() { printf "%s" "${(P)1}"; }

  __typeof() {
    whence -w "$@" | sed -e 's/^.*:[[:space:]]*//' \
                         -e 's/^command$/file/' \
                         -e 's/^hashed$/file/' \
                         -e 's/^reserved$/keyword/' \
                         -e '/^none$/d'
  }
elif [[ "${DCP_SHELL}" = "bash" ]]; then
  __valueof() { printf "%s" "${!1}"; }

  __typeof() { type -t "$@"; }
fi

# Convenience wrappers for __valueof

__is_true() { [[ "$(__valueof "$1")" = "true" ]]; }
__is_false() { [[ "$(__valueof "$1")" = "false" ]]; }

# Convenience wrappers for __typeof

__is_command() {
  local type="$(__typeof "$1")"
  [[ -n "${type}" && "${type}" != "keyword" ]]
}

__is_alias() { [[ "$(__typeof "$1")" = "alias" ]]; }
__is_function() { [[ "$(__typeof "$1")" = "function" ]]; }
__is_file() { [[ "$(__typeof "$1")" = "file" ]]; }

#
# __export_select_re: selects the names of exports matching the given regular
# expression
#

__export_select_re() { env | sed -e 's/=.*$//' -e "/$1/!d"; }

#
# __unexport: remove the given var from the environment and unset it. If the
# given var is readonly, do nothing.
#

__unexport() { declare +x "$@"; unset "$@"; }

#
# __strtoupper: upcases a string
# 
# __strtolower: downcases a string
#

__strtoupper() { printf "%s" "$1" | tr '[:lower:]' '[:upper:]'; }
__strtolower() { printf "%s" "$1" | tr '[:upper:]' '[:lower:]'; }

# __ary_join: converts an array to a string separated by the first argument
__ary_join() {
  local sep="$1"; shift
  printf "%s" "$1"; shift
  printf "%s" "${@/#/${sep}}"
}

# __ary_includes: returns true if the first argument is included in the array
__ary_includes() {
  local search="$1"; shift

  local element
  for element in "$@"; do
    if [[ "${element}" = "${search}" ]]; then
      return
    fi
  done

  return 1
}

#
# __path_select: select elements from a PATH-like string matching the given
# Perl expression
#

if __is_command perl; then
  __path_select() {
    printf "%s" "$1" \
      | perl -e "print join(':', grep { $2 } split(/:/, scalar <>))"
  }
else
  __path_select() { printf "%s" "$1"; }
fi

# Convenience wrappers for __path_select 

__path_select_str() { __path_select "$1" "\$_ eq '$2'"; }
__path_reject_str() { __path_select "$1" "\$_ ne '$2'"; }

__path_select_re() { __path_select "$1" "\$_ =~ /$2/"; }
__path_reject_re() { __path_select "$1" "\$_ !~ /$2/"; }

#
# __path_distinct: __path_select wrapper which deduplicates to the earliest
# distinct elements, thereby avoiding any change in behavior
#

__path_distinct() { __path_select "$1" '!$seen{$_}++ && $_ ne "\$PATH"'; }

# __get_job_num: returns the job number of the given PID
__get_job_num() {
  local job pid tmp
  while IFS='' read -r job; do
    pid="${job##*+}"
    IFS=' ' read -r pid tmp <<< "${pid}"

    if [[ "${pid}" = "$1" ]]; then
      local job_num="${job%%]*}"
      printf "%s" "${job_num:1}"
      return
    fi
  done < <(jobs -l)
}

# __git_is_work_tree: returns true if CWD is a Git work tree
__git_is_work_tree() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1
}

# __git_get_current_branch: prints the current Git branch
__git_get_current_branch() {
  if ! __git_is_work_tree; then
    return
  fi

  git branch 2>/dev/null | awk '$0 ~ /^\*/ { printf "%s", $2 }'
}

# __get_get_merged_branches: prints "fully merged" Git branches
__git_get_merged_branches() {
  local current_branch="$(__git_get_current_branch)"

  if [[ -z "${current_branch}" ]]; then
    return
  fi

  git branch --merged | colrm 1 2 | sed -e '/^master$/d' \
                                        -e "/^${current_branch}\$/d"
}
