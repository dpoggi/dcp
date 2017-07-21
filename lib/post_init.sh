# Add ~/.local/bin directory to PATH if it exists
if [[ -d "${HOME}/.local/bin" ]]; then
  export PATH="${HOME}/.local/bin:${PATH}"
fi

# MultiMan
. "${DCP}/lib/mm.sh"

# gpg-agent
if [[ -S "${HOME}/.gnupg/S.gpg-agent.ssh" ]]; then
  export SSH_AUTH_SOCK="${HOME}/.gnupg/S.gpg-agent.ssh"
fi

# Base16 shell colors
if [[ -r "${BASE16_SHELL}" && -z "${INSIDE_EMACS}" ]]; then
  . "${BASE16_SHELL}"
fi

# PATH deduplication
export PATH="$(__path_distinct "${PATH}")"
