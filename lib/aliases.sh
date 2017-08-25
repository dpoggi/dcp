#
# General aliases
#

alias c="clear"
alias ll="ls -la"
alias la="ls -a"
alias h="history | tail -32"

if [[ "${DCP_SHELL}" = "bash" ]]; then
  alias grep="grep --color=auto"
fi

. "${DCP}/lib/util.sh"

ext_ip() {
  local ip_version="4"
  local content_type="text/plain"

  while (( $# > 0 )); do
    case "$1" in
      --html) content_type="text/html"        ;;
      --json) content_type="application/json" ;;
      6)      ip_version="6"
    esac
    shift
  done

  curl --silent \
       "--ipv${ip_version}" \
       --header "Accept: ${content_type}" \
       "https://ip.danpoggi.com" \
       2>/dev/null

  if [[ "$?" != "0" ]]; then
    printf >&2 "Error: unable to retrieve external IP.\n"

    if [[ "${ip_version}" = "6" ]]; then
      printf >&2 "\nThis may be due to missing or incorrect IPv6 configuration.\n"
    fi
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

gdt() { git describe --tags --abbrev=0; }

gn() {
  if __git_is_work_tree; then
    return 1
  fi

  git init \
    && git add . \
    && git commit -m 'Initial commit'
}

gfco() {
  local current_branch="$(__git_get_current_branch)"

  if [[ -z "${current_branch}" ]]; then
    return 1
  fi

  local remote_branch="origin/${current_branch}"

  printf >&2 "Are you sure you want to force-checkout ${current_branch} from ${remote_branch}? "

  read -r

  if [[ "${REPLY}" != "YES" ]]; then
    printf >&2 "\nError: only YES, in all caps, will continue.\n"
    return 1
  fi

  git checkout -B "${current_branch}" "origin/${current_branch}"
}

alias grv="git remote -v"
alias ggr="git grep --break --heading --line-number"

gcb() {
  git fetch --all --prune

  local branch
  while IFS='' read -r branch; do
    git branch -d "${branch}"
  done < <(__git_get_merged_branches)
}

gitignore() {
  if [[ -z "$1" ]]; then
    return 1
  fi
  curl -sJL "https://www.gitignore.io/api/$1"
}

gpub() {
  git push origin "${1}:refs/heads/$1" \
    && git fetch origin \
    && git config "branch.${1}.remote" origin \
    && git config "branch.${1}.merge" "refs/heads/$1" \
    && git checkout "$1"
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

  while read -d $'\x00' -r file; do
    result="$(grep -n ".\\{$2\\}" "${file}" | cut -d ':' -f 1)"

    if [[ -n "${result}" ]]; then
      printf >&2 "${DCP_GREEN}%s${DCP_WHITE}:${DCP_RESET} " \
                 "$(printf "%s" "${file}" | tail -c +3)"

      while read line; do
        printf >&2 "${DCP_RED}%s${DCP_WHITE},${DCP_RESET} " "${line}"
      done < <(printf "%s" "${result}")

      printf >&2 "${DCP_RED}%s${DCP_RESET}\n" "${line}"
    fi
  done < <(find . -mindepth 1 -type f -name "*.$1" -print0 2>/dev/null)
}


#
# Utility functions
#

# Set prompt in zsh

if [[ -n "${ZSH_NAME}" ]]; then
  set_prompt() {
    . "${ZSH}/themes/${ZSH_THEME}.zsh-theme"
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

# virtualenv-independent pip

if [[ "${PIP_REQUIRE_VIRTUALENV}" = "true" ]]; then
  gpip() { PIP_REQUIRE_VIRTUALENV="" command pip "$@"; }
  gpip2() { PIP_REQUIRE_VIRTUALENV="" command pip2 "$@"; }
  gpip3() { PIP_REQUIRE_VIRTUALENV="" command pip3 "$@"; }
fi

# Maven aliases

if __is_command mvn; then
  alias mvncp="mvn clean package"
  alias mvncv="mvn clean verify"
fi
