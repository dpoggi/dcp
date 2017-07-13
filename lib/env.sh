# Common environment

export PATH="${PATH}:${DCP}/bin"

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
if [[ "${DCP_OS}" = "Darwin" ]] && hash brew 2> /dev/null; then
  export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/sbin:${PATH}"
fi

# Detect shell + invocation (approximately close enough)

. "${DCP}/lib/detect_shell.sh"

# Local environment

. "${DCP}/localenv"

# Check for our spot in XDG_CONFIG_HOME

readonly DCP_CONFIG_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/dcp"

if [[ ! -e "${DCP_CONFIG_DIR}" ]]; then
  mkdir -p "${DCP_CONFIG_DIR}"
fi

# Add GOPATH bin directories to PATH, if present

if [[ -n "${GOPATH}" ]]; then
  export PATH="${PATH}:$(printf "%s" "${GOPATH}" | sed -e 's#:#/bin:#g' -e 's#$#/bin#')"
fi
