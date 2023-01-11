# Prepend ~/.local/bin directory to PATH if it exists
if [[ -d "${HOME}/.local/bin" ]]; then
  export PATH="${HOME}/.local/bin:${PATH}"
fi

# Travis CI completions
if [[ -s "${HOME}/.travis/travis.sh" ]]; then
  . "${HOME}/.travis/travis.sh"
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

# Local post-init tasks
if [[ -s "${DCP}/localpostrc" ]]; then
  . "${DCP}/localpostrc"
fi

# PATH deduplication
export PATH="$(__path_distinct "${PATH}")"

if [[ -n "${INFOPATH}" ]]; then
  export INFOPATH="$(__path_distinct "${INFOPATH}"):"
fi

if [[ -n "${MANPATH}" ]]; then
  export MANPATH="$(__path_distinct "${MANPATH}"):"
fi
