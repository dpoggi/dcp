# Component functions

__ps1_preamble() {
  if [[ "${UID}" = "0" ]]; then
    printf '%b' "${DCP_RED}"
  else
    printf '%b' "${DCP_GREEN}"
  fi

  printf '\\u%b@%b\\h' "${DCP_WHITE}" "${DCP_CYAN}"

  printf '%b:%b\\w' "${DCP_WHITE}" "${DCP_PURPLE}"
}

__ps1_git() {
  printf '%b$(%s)' "${DCP_YELLOW}" "${DCP}/libexec/git_current_branch.sh --ps1"
}

__ps1_uid() {
  if [[ "${DPOGGI_TWOLINE}" = "true" ]]; then
    printf '\n'
  else
    printf ' '
  fi

  printf '%b\\$%b ' "${DCP_RED}" "${DCP_RESET}"
}

# Set prompt

set_prompt() {
  PS1="$(__ps1_preamble)$(__ps1_git)$(__ps1_uid)"
}
