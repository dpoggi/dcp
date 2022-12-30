#
# __valueof: dereference a variable by name
# __typeof: prints the type of command the given name is hashed as
#

if __is_zsh; then
  __valueof() { printf '%s\n' "${(P)1}"; }
  __typeof() {
    local name type

    for name in "$@"; do
      type="$(whence -w "${name}")"
      type="${type#*: }"
      type="${type/command/file}"
      type="${type/hashed/file}"
      type="${type/reserved/keyword}"

      if [[ "${type}" != "none" ]]; then
        printf '%s\n' "${type}"
      elif (($# == 1)); then
        return 1
      fi
    done
  }
  __is_alias() { [[ "$(whence -w "$1")" = *": alias" ]]; }
  __is_function() { [[ "$(whence -w "$1")" = *": function" ]]; }
elif __is_bash; then
  __valueof() { printf '%s\n' "${!1}"; }
  __typeof() { type -t "$@"; }
  __is_alias() { [[ "$(type -t "$1")" = "alias" ]]; }
  __is_function() { [[ "$(type -t "$1")" = "function" ]]; }
fi

#
# Convenience wrappers for __valueof
#

__is_true() { [[ "$(__valueof "$1")" = "true" ]]; }
__is_false() { [[ "$(__valueof "$1")" = "false" ]]; }

#
# Convenience wrappers for __typeof
#

__is_command() {
  local type="$(__typeof "$1")"
  [[ -n "${type}" && "${type}" != "keyword" ]]
}

__is_file() {
  [[ "$(__typeof "$1")" = "file" ]]
}

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
__unalias() { unalias "$@" 2>/dev/null; }
__unfunction() { unset -f "$@" 2>/dev/null; }

__uncommand() {
  __unalias "$@" || :
  __unfunction "$@" || :
}

# __strtoupper: upcases strings
__strtoupper() {
  while (($# > 0)); do
    awk '{ print toupper($0) }' <<<"$1"
    shift
  done
}

# __strtolower: downcases strings
__strtolower() {
  while (($# > 0)); do
    awk '{ print tolower($0) }' <<<"$1"
    shift
  done
}

# __strtoarg: surrounds strings with single quotes, escaping any quotes inside
__strtoarg() {
  local quote="'\\''"

  while (($# > 0)); do
    printf "'%s'\\n" "${1//\'/${quote}}"
    shift
  done
}

# __ary_join: converts an array to a string separated by the first argument
__ary_join() {
  local separator="$1"; shift
  local first="$1"; shift
  printf '%s' "${first}"
  printf '%s' "${@/#/${separator}}"
}

# __ary_includes: returns true if the first argument is included in the array
__ary_includes() {
  local search="$1"; shift

  while (($# > 0)); do
    if [[ "$1" = "${search}" ]]; then
      return
    fi
    shift
  done

  return 1
}

#
# __path_select: select elements from a PATH-like string matching the given
# Perl expression
#

if __is_command perl; then
  __path_select() {
    perl -e '
      my @dirs = split(/:/, scalar <>);
      chomp(@dirs);
      my $pathlist = join(":", grep { '"$2"' } @dirs);
      print $pathlist;
    ' <<<"$1"
  }
else
  __path_select() {
    printf '%s\n' "$1"
  }
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
__path_distinct() {
  __path_select "$1" '!$seen{$_}++ && length $_ && $_ ne "\$PATH"'
}

# __get_job_num: returns the job number of the given PID
__get_job_num() {
  local job pid tmp
  while IFS='' read -r job; do
    pid="${job##*+}"
    IFS=' ' read -r pid tmp <<< "${pid}"

    if [[ "${pid}" = "$1" ]]; then
      local job_num="${job%%]*}"
      printf '%s\n' "${job_num:1}"
      return
    fi
  done < <(jobs -l)
}

# __git_is_cwd_worktree: returns true if CWD is a Git worktree
__git_is_cwd_worktree() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1
}

# __git_get_current_branch: prints the current Git branch
__git_get_current_branch() {
  if __git_is_cwd_worktree; then
    git branch 2>/dev/null | awk '$1 == "*" { print substr($0, 3) }'
  else
    return 1
  fi
}

# __get_get_merged_branches: prints "fully merged" Git branches
__git_get_merged_branches() {
  local current_branch

  if ! current_branch="$(__git_get_current_branch)"; then
    return 1
  fi

  git branch --merged 2>/dev/null | awk '{
    branch=substr($0, 3)

    if (branch != "master" && branch != "main" && branch != "'"${current_branch}"'") {
      print branch
    }
  }'
}
