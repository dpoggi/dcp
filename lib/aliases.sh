#
# General aliases
#

alias c="clear"
alias ll="ls -la"
alias la="ls -a"
alias h="history | tail -32"

ext_ip() {
  local version
  local json="false"

  while [[ "$#" -gt "0" ]]; do
    [[ "$1" = "--json" ]] && json="true" || version="$1"
    shift
  done
  [[ "${version}" = "4" || "${version}" = "6" ]] || version="4"

  if [[ "${json}" = "true" ]]; then
    curl --silent "--ipv${version}" --header "Accept: application/json" \
         "https://ip.danpoggi.com"
  else
    curl --silent "--ipv${version}" "https://ip.danpoggi.com"
  fi
}


#
# Git aliases
#

alias ga="git add"
alias gp="git push"
alias gpl="git pull"
alias gl="git log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
alias gll="git log --stat --oneline --decorate"
alias gs="git status"
alias gst="git stash"
alias gsa="git stash apply"
alias gsl="git stash list"
alias gd="git diff"
alias gds="git diff --staged"
alias gc="git commit"
alias gcm="git commit -m"
alias gco="git checkout"
alias gb="git branch"
alias gf="git fetch"
alias gr="git rebase"
alias gm="git merge"
alias gn="git init && git add . && git commit -m 'Initial commit.'"
alias grv="git remote -v"
alias ggr="git grep --break --heading --line-number"

gcb() {
  local current_branch="$(git branch 2> /dev/null | sed -e '/^[^*]/d' | colrm 1 2)"
  git fetch --prune
  git branch --merged \
    | colrm 1 2 \
    | grep -v "^${current_branch}$" \
    | grep -v "^master$" \
    | xargs git branch -d
}

gitignore() {
  curl -sJL "https://raw.githubusercontent.com/github/gitignore/master/${1}.gitignore"
}

gpub() {
  git push origin "${1}:refs/heads/$1"
  git fetch origin
  git config "branch.${1}.remote" origin
  git config "branch.${1}.merge" "refs/heads/$1"
  git checkout "$1"
}


#
# Find files of extension $1 with lines longer than $2 columns
#

find_long_lines() {
  if [[ "$#" != "2" ]]; then
    printf >&2 "Usage: find_long_lines <ext> <#>\n"
    return 1
  fi

  local file result line
  while read file; do
    result="$(grep -n ".\\{$2\\}" "${file}" | cut -d ':' -f 1)"
    if [[ -n "${result}" ]]; then
      printf >&2 "${DCP_GREEN}%s${DCP_WHITE}:${DCP_RESET} " \
                 "$(printf "%s" "${file}" | tail -c +3)"
      while read line; do
        printf >&2 "${DCP_RED}%s${DCP_WHITE},${DCP_RESET} " "${line}"
      done < <(printf "%s" "${result}")
      printf >&2 "${DCP_RED}%s${DCP_RESET}\n" "${line}"
    fi
  done < <(find . -mindepth 1 -type f -name "*.$1" -print)
}


#
# PS1
#

# Component functions
__ps1_preamble() {
  [[ "${UID}" = "0" ]] && printf "${DCP_PS1_RED}" || printf "${DCP_PS1_GREEN}"
  printf "\\\\u${DCP_PS1_WHITE}@${DCP_PS1_CYAN}\\h"
  printf "${DCP_PS1_WHITE}:${DCP_PS1_PURPLE}\\w"
}
__ps1_git() {
  printf "${DCP_PS1_YELLOW}\$(${DCP}/bin/__ps1_git_branch)"
}
__ps1_uid() {
  [[ "${DPOGGI_TWOLINE}" = "true" ]] && printf "\n" || printf " "
  printf "${DCP_PS1_RED}\\\$${DCP_PS1_RESET} "
}

# Set prompt in either shell
if [[ -n "${ZSH_NAME}" ]]; then
  set_prompt() {
    source "${ZSH}/themes/${ZSH_THEME}.zsh-theme"
  }
else
  set_prompt() {
    export PS1="$(__ps1_preamble)$(__ps1_git)$(__ps1_uid)"
  }
fi

# One-line or two-line prompt
oneline() {
  export DPOGGI_TWOLINE="false"
  set_prompt
}
twoline() {
  export DPOGGI_TWOLINE="true"
  set_prompt
}


#
# Utility functions
#

# Use shell functions to override binaries whilst respecting $PATH
if [[ -n "${ZSH_NAME}" ]]; then
  __bin_path() {
    whence -p "$1"
  }
else
  __bin_path() {
    type -P "$1"
  }
fi

# Gets job number from PID after &ing a process
__job_num() {
  local num="$(jobs -l \
                 | grep -F "$1" \
                 | tail -n 1 \
                 | cut -d ' ' -f 1 \
                 | sed -e 's/[^[:digit:]]//g')"
  if [[ -z "${num}" ]]; then
    return 1
  fi
  printf "%s" "${num}"
}

# Filter components from PATH-like var
__path_filter() {
  local arr="$1"; shift
  local ifs="${IFS}"; IFS="|"
  local args="($*)"; IFS="${ifs}"

  printf "%s" "$(printf "%s" "${arr}" | perl -p \
      -e "s#:[^:]*${args}[^:]*:#:#g;" \
      -e "s#:[^:]*${args}[^:]*##g;" \
      -e "s#[^:]*${args}[^:]*:##g;")"
}

# virtualenv-independent pip
gpip() {
  PIP_REQUIRE_VIRTUALENV="" pip "$@"
}

# docker-machine environment
dm_env() {
  if [[ "$1" != "none" ]]; then
    eval "$(docker-machine env "$1")"
  else
    unset DOCKER_TLS_VERIFY
    unset DOCKER_HOST
    unset DOCKER_CERT_PATH
    unset DOCKER_MACHINE_NAME
  fi
}

# Kill running Emacsen
__kill_emacs() {
  emacsclient --eval "(kill-emacs)"
}

# Restart shell with version managers enabled/disabled

if [[ -n "${ZSH_NAME}" ]]; then
  if [[ "$-" = *l* ]]; then
    DCP_SHELL_INVOCATION=(zsh --login)
  else
    DCP_SHELL_INVOCATION=(zsh)
  fi
else
  if shopt -q login_shell 2> /dev/null; then
    readonly DCP_SHELL_INVOCATION=(bash --login)
  else
    readonly DCP_SHELL_INVOCATION=(bash)
  fi
fi

yes_managers() {
  unset DCP_DISABLE_MANAGERS
  unset DCP_DISABLE_NVM
  unset DCP_DISABLE_PYENV
  unset DCP_DISABLE_RVM
  unset DCP_DISABLE_RBENV
  exec ${DCP_SHELL_INVOCATION[*]}
}

no_managers() {
  DCP_DISABLE_MANAGERS="true" exec ${DCP_SHELL_INVOCATION[*]}
}
