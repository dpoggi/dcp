#
# Common environment
#

export PATH="${PATH}:${DCP}/bin"

readonly DCP_OS="$(uname -s)"

export EDITOR="vim"
export LS_OPTIONS="--color=auto"
export DPOGGI_TWOLINE="true"
export CLICOLOR="1"


#
# Colors!
#

readonly DCP_RED="\033[0;31m"
readonly DCP_GREEN="\033[0;32m"
readonly DCP_WHITE="\033[0;37m"
readonly DCP_BLUE="\033[0;34m"
readonly DCP_CYAN="\033[0;36m"
readonly DCP_PURPLE="\033[0;35m"
readonly DCP_YELLOW="\033[0;33m"
readonly DCP_RESET="\033[0m"


#
# Check for Homebrew
#

# Guard for Darwin because I know nothing about Linuxbrew, and this PATH order
# would be inappropriate for most distros.
if [[ "${DCP_OS}" = "Darwin" && -x "/usr/local/bin/brew" ]]; then
  export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/sbin:${PATH}"
fi


#
# Detect shell + invocation (approximately close enough)
#

. "${DCP}/lib/detect_shell.sh"


#
# Local environment
#

. "${DCP}/localenv"

readonly DCP_CONFIG_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/dcp"

if [[ ! -e "${DCP_CONFIG_DIR}" ]]; then
  mkdir -p "${DCP_CONFIG_DIR}"
fi

# Add GOPATH bin directories to PATH, if present

if [[ -n "${GOPATH}" ]]; then
  export PATH="${PATH}:$(printf "%s" "${GOPATH}" | sed -e 's#:#/bin:#g' -e 's#$#/bin#')"
fi


#
# __unexport: Completely rid yourself of a currently exported var
#

__unexport() {
  typeset +x "$1"
  unset "$1"
}


#
# __path_select: Select elements from a PATH-like string by Perl expression
#
# __path_distinct: Use __path_select to simplify a PATH-like string down to its
# earliest distinct elements. That is, remove duplicates without altering
# behavior. Also filter out accidental literal '$PATH's, which is a thing.
#

if hash perl 2> /dev/null; then
  __path_select() {
    printf "%s" "$1" \
      | perl -e "print join(\":\", grep { $2 } split(/:/, scalar <>))"
  }
else
  __path_select() {
    printf "%s" "$1"
  }
fi

__path_distinct() {
  __path_select "$1" '!$seen{$_}++ && $_ ne "\$PATH"'
}

export PATH="$(__path_distinct "${PATH}")"
