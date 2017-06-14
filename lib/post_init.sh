#
# Add ~/.local/bin directory to PATH if available
#

if [[ -d "${HOME}/.local/bin" ]]; then
  export PATH="${HOME}/.local/bin:${PATH}"
fi


if [[ -n "${DCP_PREVENT_DISABLE}" ]]; then
  typeset +x DCP_DISABLE_MANAGERS
  unset DCP_DISABLE_MANAGERS

  typeset +x DCP_DISABLE_NVM
  unset DCP_DISABLE_NVM

  typeset +x DCP_DISABLE_OPAM
  unset DCP_DISABLE_OPAM

  typeset +x DCP_DISABLE_PYENV
  unset DCP_DISABLE_PYENV

  typeset +x DCP_DISABLE_RVM
  unset DCP_DISABLE_RVM
  typeset +x DCP_DISABLE_RBENV
  unset DCP_DISABLE_RBENV

  typeset +x DCP_DISABLE_RUSTUP
  unset DCP_DISABLE_RUSTUP

  typeset +x DCP_PREVENT_DISABLE
  unset DCP_PREVENT_DISABLE
fi

if [[ -n "${DCP_DISABLE_MANAGERS}" ]]; then
  export DCP_DISABLE_NVM="true"
  export DCP_DISABLE_OPAM="true"
  export DCP_DISABLE_PYENV="true"
  export DCP_DISABLE_RVM="true"
  export DCP_DISABLE_RBENV="true"
  export DCP_DISABLE_RUSTUP="true"

  typeset +x DCP_DISABLE_MANAGERS
  unset DCP_DISABLE_MANAGERS
fi


#
# Add rustup (~/.cargo/bin) directory to PATH if available
#

if [[ -z "${DCP_DISABLE_RUSTUP}" ]]; then
  if [[ -d "${HOME}/.cargo" ]]; then
    export PATH="${HOME}/.cargo/bin:${PATH}"
  fi
else
  export PATH="$(__path_select "${PATH}" '$_ !~ /cargo/')"
fi


#
# Configure OPAM environment if available
#

if [[ -z "${DCP_DISABLE_OPAM}" ]]; then
  if [[ "${DCP_SHELL}" = "bash" && -s "${HOME}/.opam/opam-init/init.sh" ]]; then
    source "${HOME}/.opam/opam-init/init.sh"
  elif [[ "${DCP_SHELL}" = "zsh" && -s "${HOME}/.opam/opam-init/init.zsh" ]]; then
    source "${HOME}/.opam/opam-init/init.zsh"
  fi
else
  export PATH="$(__path_select "${PATH}" '$_ !~ /opam/')"
fi


#
# Load nvm if available
#

if [[ -z "${DCP_DISABLE_NVM}" ]]; then
  [[ -d "${HOME}/.nvm" ]] && export NVM_DIR="${HOME}/.nvm"
  if [[ -s "${NVM_DIR}/nvm.sh" ]]; then
    source "${NVM_DIR}/nvm.sh"
  elif [[ -s "/usr/local/opt/nvm/nvm.sh" ]]; then
    # Because for some reason this doesn't end up in PATH with Homebrew...
    source "/usr/local/opt/nvm/nvm.sh"
  fi
elif [[ -z "${DCP_DISABLE_NVM_NOFILTER}" ]]; then
  export PATH="$(__path_select "${PATH}" '$_ !~ /nvm/')"
fi


#
# Load pyenv + pyenv-virtualenv if available
#

if [[ -z "${DCP_DISABLE_PYENV}" ]]; then
  if [[ -d "${HOME}/.pyenv/shims" ]]; then
    export PYENV_ROOT="${HOME}/.pyenv"
    [[ -d "${PYENV_ROOT}/bin" ]] && export PATH="${PYENV_ROOT}/bin:${PATH}"
  fi
  hash pyenv 2>/dev/null && eval "$(pyenv init -)"
  if hash pyenv-virtualenv-init 2>/dev/null; then
    export PYENV_VIRTUALENV_DISABLE_PROMPT="1"
    eval "$(pyenv-virtualenv-init -)"
  fi
else
  export PATH="$(__path_select "${PATH}" '$_ !~ /pyenv/')"
fi


#
# Load rbenv or RVM (if you have to, I guess) if available
#

if [[ -d "${HOME}/.rvm" ]]; then
  if [[ -z "${DCP_DISABLE_RVM}" ]]; then
    export PATH="${PATH}:${HOME}/.rvm/bin"
    [[ -s "${HOME}/.rvm/scripts/rvm" ]] && source "${HOME}/.rvm/scripts/rvm"
  else
    export PATH="$(__path_select "${PATH}" '$_ !~ /rvm/')"
  fi
else
  if [[ -z "${DCP_DISABLE_RBENV}" ]]; then
    if [[ -d "${HOME}/.rbenv/shims" ]]; then
      export RBENV_ROOT="${HOME}/.rbenv"
      [[ -d "${RBENV_ROOT}/bin" ]] && export PATH="${RBENV_ROOT}/bin:${PATH}"
    fi
    hash rbenv 2>/dev/null && eval "$(rbenv init -)"
  else
    export PATH="$(__path_select "${PATH}" '$_ !~ /rbenv/')"
  fi
fi


#
# Final steps
#

# GPG Agent

if [[ -S "${HOME}/.gnupg/S.gpg-agent.ssh" ]]; then
  export SSH_AUTH_SOCK="${HOME}/.gnupg/S.gpg-agent.ssh"
fi

if [[ -s "${HOME}/.gnupg/gpg-agent-info" ]]; then
  . "${HOME}/.gnupg/gpg-agent-info"

  export GPG_AGENT_INFO
  export SSH_AGENT_PID
fi

# Base16 colors, if the script path has been set locally
[[ -s "${BASE16_SHELL}" && -z "${INSIDE_EMACS}" ]] && source "${BASE16_SHELL}"

# Another round of PATH deduplication after version managers load
export PATH="$(__path_distinct "${PATH}")"
