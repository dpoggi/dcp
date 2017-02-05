#
# General aliases
#

alias c="clear"
alias ll="ls -la"
alias la="ls -a"
alias h="history | tail -32"

if hash emacsclient 2> /dev/null; then
  gecl() {
    emacsclient -c &
    disown %$(__job_num "$!")
  }

  cecl() {
    emacsclient -nw
  }
fi

ext_ip() {
  local ip_version="4"
  local content_type="text/plain"

  while [[ "$#" -gt "0" ]]; do
    case "$1" in
      --json|-j)
        content_type="application/json"
        ;;
      6)
        ip_version="6"
        ;;
    esac
    shift
  done

  curl --silent \
       "--ipv${ip_version}" \
       --header "Accept: ${content_type}" \
       "https://ip.danpoggi.com" \
       2> /dev/null

  if [[ "$?" != "0" ]]; then
    printf >&2 "Error: unable to retrieve external IP.\n"

    if [[ "${ip_version}" = "6" ]]; then
      printf >&2 "\nThis network may not be configured for IPv6.\n"
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

__git_current_branch() {
  git branch 2> /dev/null | awk '$0 ~ /^\*/ { printf "%s", $2 }'
}

gdt() {
  git describe --tags --abbrev=0
}

gn() {
  if [[ -e ".git" ]]; then
    return 1
  fi
  git init \
    && git add . \
    && git commit -m 'Initial commit.'
}

gfco() {
  local current_branch="$(__git_current_branch)"
  if [[ -z "${current_branch}" ]]; then
    return 1
  fi

  git checkout -B "${current_branch}" "origin/${current_branch}"
}

alias grv="git remote -v"
alias ggr="git grep --break --heading --line-number"

gcb() {
  local current_branch="$(__git_current_branch)"
  if [[ -z "${current_branch}" ]]; then
    return 1
  fi

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
  local job_num="$(jobs -l \
                   | grep -F " $1 " \
                   | tail -n 1 \
                   | cut -d ' ' -f 1 \
                   | sed -e 's/[^0-9]//g')"

  if [[ -z "${job_num}" ]]; then
    return 1
  fi

  printf "%s" "${job_num}"
}

# virtualenv-independent pip
gpip() {
  PIP_REQUIRE_VIRTUALENV="" pip "$@"
}

# Restart shell with version managers enabled/disabled

if [[ -n "${ZSH_NAME}" ]]; then
  if [[ "$-" = *l* ]]; then
    readonly DCP_SHELL_INVOCATION="exec -l zsh -l"
  else
    readonly DCP_SHELL_INVOCATION="exec zsh"
  fi
else
  if shopt -q login_shell 2> /dev/null; then
    readonly DCP_SHELL_INVOCATION="exec -l bash -l"
  else
    readonly DCP_SHELL_INVOCATION="exec bash"
  fi
fi
export DCP_SHELL_INVOCATION

yes_managers() {
  export DCP_PREVENT_DISABLE="true"
  eval "${DCP_SHELL_INVOCATION}"
}

no_managers() {
  export DCP_DISABLE_MANAGERS="true"
  eval "${DCP_SHELL_INVOCATION}"
}

# JABBA

if hash mvn 2> /dev/null; then
  generate_mvn_wrapper() {
    mvn -N io.takari:maven:wrapper

    if [[ "$?" != "0" ]]; then
      return "$?"
    fi

    # Use my totally wicked cool Maven distribution... hehehe
    printf "%s\n" \
      "distributionUrl=https://s3.amazonaws.com/dcp-java/apache-maven-deluxe-3.3.9-bin.zip" \
      > .mvn/wrapper/maven-wrapper.properties

    # Fix up DOS batch wrapper: incorrect comment syntax and strange CRLFs
    perl -i -p \
      -e 's/^#/\@REM/g;' \
      -e 's/\R/\015\012/g;' \
      mvnw.cmd
  }
fi
