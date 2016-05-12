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
  local current_branch="$(git branch 2>/dev/null | sed -e '/^[^*]/d' | colrm 1 2)"
  git fetch --prune
  git branch --merged | \
    colrm 1 2 | \
    grep -v "^${current_branch}$" | \
    grep -v "^master$" | \
    xargs git branch -d
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

# For oh-my-zsh jira plugin
gbjira() {
  if [[ -z "${BASH}" && "$(whence -w jira)" = "jira: function" ]]; then
    local branch="$("${DCP}/bin/__ps1_git_branch" | sed -e 's/[\(\)]//g')"
    if [[ -n "${branch}" ]]; then
      jira "${branch}"
    else
      printf >&2 "Unable to get the current branch.\n"
      return 1
    fi
  fi
}


#
# PS1
#

# Colors!
c_red="\[\033[0;31m\]"
c_green="\[\033[0;32m\]"
c_white="\[\033[0;37m\]"
c_cyan="\[\033[0;36m\]"
c_purple="\[\033[0;35m\]"
c_yellow="\[\033[0;33m\]"
c_reset="\[\033[0m\]"

# Component functions
__ps1_preamble() {
  [[ "${UID}" = "0" ]] && printf "${c_red}" || printf "${c_green}"
  printf "\\\\u${c_white}@${c_cyan}\\h${c_white}:${c_purple}\\w"
}
__ps1_git() {
  printf "${c_yellow}\$(${DCP}/bin/__ps1_git_branch)"
}
__ps1_uid() {
  [[ "${DPOGGI_TWOLINE}" = "true" ]] && printf "\n" || printf " "
  printf "${c_red}\\\$${c_reset} "
}

# Set prompt in either shell
set_prompt() {
  if [[ -n "${BASH}" ]]; then
    export PS1="$(__ps1_preamble)$(__ps1_git)$(__ps1_uid)"
  elif [[ -n "${ZSH}" ]]; then
    source "${ZSH}/themes/${ZSH_THEME}.zsh-theme"
  fi
}

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
__bin_path() {
  [[ -n "${BASH}" ]] && type -P "$1" || whence -p "$1"
}

# Gets job number from PID after &ing a process
__jobno() {
  jobs -l | grep -F "$1" | awk '{ print $1 }' | sed -e 's/[^0-9]//g'
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
  eval "$(docker-machine env "$1")"
}

# Kill running Emacsen
__kill_emacs() {
  emacsclient --eval "(kill-emacs)"
}


#
# Clipboard functions
#

if hash pbcopy 2>/dev/null && hash pbpaste 2>/dev/null; then
  DCP_CBCOPY="pbcopy"
  DCP_CBPASTE="pbpaste"
elif hash xsel 2>/dev/null; then
  DCP_CBCOPY="xsel --clipboard --input"
  DCP_CBPASTE="xsel --clipboard --output"
fi

cbcopy() {
  [[ -n "${DCP_CBCOPY}" ]] || return 1
  if [[ -e "$1" ]]; then
    local file="$1"
    shift
    cat "${file}" | ${DCP_CBCOPY} "$@"
  else
    ${DCP_CBCOPY} "$@"
  fi
}

cbpaste() {
  [[ -n "${DCP_CBPASTE}" ]] || return 1
  if [[ -n "$1" ]]; then
    local file="$1"
    shift
    ${DCP_CBPASTE} "$@" >>"${file}"
  else
    ${DCP_CBPASTE} "$@"
  fi
}


#
# Easter egg!
#

if hash cowsay 2>/dev/null; then
  cornholio() {
    cowsay -f beavis.zen "hehehehehehehehe"
  }
fi
