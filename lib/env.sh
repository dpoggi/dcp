# Common environment

# Append ~/.dcp/bin directory to PATH
export PATH="${PATH}:${DCP}/bin"

# Memoize `uname -s`
readonly DCP_OS="$(uname -s)"

export EDITOR="vim"
export CLICOLOR="1"
export LS_OPTIONS="--color=auto"
export DPOGGI_TWOLINE="true"

# Colors!

readonly DCP_RED="\033[0;31m"
readonly DCP_GREEN="\033[0;32m"
readonly DCP_WHITE="\033[0;37m"
readonly DCP_BLUE="\033[0;34m"
readonly DCP_CYAN="\033[0;36m"
readonly DCP_PURPLE="\033[0;35m"
readonly DCP_YELLOW="\033[0;33m"
readonly DCP_RESET="\033[0;39;49m"

# Check for Homebrew

# Guard for macOS because I know nothing about Linuxbrew, and this PATH order
# would be inappropriate for most distros.
if [[ "${DCP_OS}" = "Darwin" ]]; then
  if [[ -x "/usr/local/bin/brew" ]]; then
    export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/sbin:${PATH}"
  fi

  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(
      /opt/homebrew/bin/brew shellenv | sed \
        -e 's|\${PATH+:\$PATH}";$|${PATH:+:${PATH}}";|' \
        -e 's|\${MANPATH+:\$MANPATH}:";$|${MANPATH:+:${MANPATH}}:";|' \
        -e 's|:\${INFOPATH:-}";$|${INFOPATH:+:${INFOPATH}}:";|'
    )"
  fi
fi

# Detect shell + invocation (approximately close enough)
. "${DCP}/lib/detect_shell.sh"

# Local environment
if [[ -s "${DCP}/localenv" ]]; then
  . "${DCP}/localenv"
fi

#
# Check for our spots in XDG_CONFIG_HOME and XDG_DATA_HOME
#

readonly DCP_CONFIG_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/dcp"
if [[ ! -e "${DCP_CONFIG_DIR}" ]]; then
  mkdir -p "${DCP_CONFIG_DIR}"
fi

readonly DCP_DATA_DIR="${XDG_DATA_HOME:-${HOME}/.local/share}/dcp"
if [[ ! -e "${DCP_DATA_DIR}" ]]; then
  mkdir -p "${DCP_DATA_DIR}"
fi

# Add GOPATH bin directories to PATH, if present
if [[ -n "${GOPATH}" ]]; then
  export PATH="${PATH}:$(printf "%s" "${GOPATH}" | sed -e 's#:#/bin:#g' -e 's#$#/bin#')"
fi
