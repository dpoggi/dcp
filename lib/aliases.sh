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
    && git commit -m 'Initial commit'
}

gfco() {
  local current_branch="$(__git_current_branch)"

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
  if [[ "$#" -lt "1" ]]; then
    return 1
  fi

  curl -sJL "https://www.gitignore.io/api/${1}"
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
  done < <(find . -mindepth 1 -type f -name "*.$1" -print0)
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
  printf "${DCP_PS1_YELLOW}\$(${DCP}/libexec/ps1_git_branch.sh)"
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

enable_managers() {
  export DCP_PREVENT_DISABLE="true"
  eval "${DCP_SHELL_INVOCATION}"
}

disable_managers() {
  export DCP_DISABLE_MANAGERS="true"
  eval "${DCP_SHELL_INVOCATION}"
}

enable_rbenv() {
  declare +x DCP_DISABLE_RBENV
  unset DCP_DISABLE_RBENV
  eval "${DCP_SHELL_INVOCATION}"
}

enable_rvm() {
  declare +x DCP_DISABLE_RVM
  unset DCP_DISABLE_RVM
  eval "${DCP_SHELL_INVOCATION}"
}

enable_pyenv() {
  declare +x DCP_DISABLE_PYENV
  unset DCP_DISABLE_PYENV
  eval "${DCP_SHELL_INVOCATION}"
}

enable_nvm() {
  declare +x DCP_DISABLE_NVM
  unset DCP_DISABLE_NVM
  eval "${DCP_SHELL_INVOCATION}"
}

enable_opam() {
  declare +x DCP_DISABLE_OPAM
  unset DCP_DISABLE_OPAM
  eval "${DCP_SHELL_INVOCATION}"
}

enable_rustup() {
  declare +x DCP_DISABLE_RUSTUP
  unset DCP_DISABLE_RUSTUP
  eval "${DCP_SHELL_INVOCATION}"
}

# JABBA

__git_files_write() {
  if [[ ! -e ".gitattributes" ]]; then
    cat "${DCP}/share/gitignore/$1.gitattributes" > .gitattributes
  else
    printf >&2 ".gitattributes file already exists, skipping\n"
  fi

  if [[ ! -e ".gitignore" ]]; then
    cat "${DCP}/share/gitignore/$1.gitignore" > .gitignore
  else
    printf >&2 ".gitignore file already exists, skipping\n"
  fi
}

if hash mvn 2> /dev/null; then
  mvn_wrapper() {
    local write_git_files="false"

    while [[ "$#" -gt "0" ]]; do
      case "$1" in
        --help|-h)
          printf >&2 "Usage: %s [--write-git-files|-g]\n" "$0"
          return
          ;;
        --write-git-files|-g)
          write_git_files="true"
          ;;
        *)
          printf >&2 "Invalid argument: %s\n" "$1"
          return 1
      esac

      shift
    done

    if [[ -d ".mvn/wrapper" || -x "mvnw" ]]; then
      printf >&2 "Existing Maven wrapper detected. Remove first (y/n)? "

      read -r

      if [[ "${REPLY}" = y* || "${REPLY}" = Y* ]]; then
        rm -rf mvnw mvnw.cmd .mvn
      fi
    fi

    mvn -N io.takari:maven:wrapper

    local exit_status="$?"

    if [[ "${exit_status}" != "0" ]]; then
      return "${exit_status}"
    fi

    chmod 755 mvnw
    chmod 644 mvnw.cmd .mvn/wrapper/maven-wrapper.{jar,properties}

    # Fix yet another script bug in the Maven wrapper
		perl -pi -e 's/^\s*echo \$MAVEN_PROJECTBASEDIR$//' mvnw

    if [[ "${write_git_files}" = "true" ]]; then
      __git_files_write java
    fi
  }
fi

if hash gradle 2> /dev/null; then
  gradle_wrapper() {
    local write_git_files="false"

    while [[ "$#" -gt "0" ]]; do
      case "$1" in
        --help|-h)
          printf >&2 "Usage: %s [--write-git-files|-g]\n" "$0"
          return
          ;;
        --write-git-files|-g)
          write_git_files="true"
          ;;
        *)
          printf >&2 "Invalid argument: %s\n" "$1"
          return 1
      esac

      shift
    done

    if [[ -d "gradle/wrapper" || -x "gradlew" ]]; then
      printf >&2 "Existing Gradle wrapper detected. Remove first (y/n)? "

      read -r

      if [[ "${REPLY}" = y* || "${REPLY}" = Y* ]]; then
        rm -rf .gradle gradle gradlew gradlew.bat
      fi
    fi

    gradle --no-daemon wrapper

    local exit_status="$?"

    if [[ "${exit_status}" != "0" ]]; then
      return "${exit_status}"
    fi

    if [[ "${write_git_files}" = "true" ]]; then
      __git_files_write java
    fi
  }
fi
