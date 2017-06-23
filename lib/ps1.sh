# Wrapped colors

readonly DCP_PS1_RED="\[${DCP_RED}\]"
readonly DCP_PS1_GREEN="\[${DCP_GREEN}\]"
readonly DCP_PS1_WHITE="\[${DCP_WHITE}\]"
readonly DCP_PS1_BLUE="\[${DCP_BLUE}\]"
readonly DCP_PS1_CYAN="\[${DCP_CYAN}\]"
readonly DCP_PS1_PURPLE="\[${DCP_PURPLE}\]"
readonly DCP_PS1_YELLOW="\[${DCP_YELLOW}\]"
readonly DCP_PS1_RESET="\[${DCP_RESET}\]"

# Component functions

__ps1_preamble() {
  if [[ "${UID}" = "0" ]]; then
    printf "${DCP_PS1_RED}"
  else
    printf "${DCP_PS1_GREEN}"
  fi

  printf "\\\\u${DCP_PS1_WHITE}@${DCP_PS1_CYAN}\\h"

  printf "${DCP_PS1_WHITE}:${DCP_PS1_PURPLE}\\w"
}

__ps1_git() {
  printf "${DCP_PS1_YELLOW}\$(${DCP}/libexec/ps1_git_branch.sh)"
}

__ps1_uid() {
  if [[ "${DPOGGI_TWOLINE}" = "true" ]]; then
    printf "\n"
  else
    printf " "
  fi

  printf "${DCP_PS1_RED}\\\$${DCP_PS1_RESET} "
}

# Set prompt

set_prompt() {
  PS1="$(__ps1_preamble)$(__ps1_git)$(__ps1_uid)"
}
