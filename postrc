if [[ -n "${DCP_DISABLE_MANAGERS}" ]]; then
  DCP_DISABLE_NVM="true"
  DCP_DISABLE_PYENV="true"
  DCP_DISABLE_RVM="true"
  DCP_DISABLE_RBENV="true"
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
else
  export PATH="$(__path_filter "${PATH}" "nvm")"
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
  export PATH="$(__path_filter "${PATH}" "pyenv")"
fi


#
# Load rbenv or RVM (if you have to, I guess) if available
#

if [[ -d "${HOME}/.rvm" ]]; then
  if [[ -z "${DCP_DISABLE_RVM}" ]]; then
    export PATH="${PATH}:${HOME}/.rvm/bin"
    [[ -s "${HOME}/.rvm/scripts/rvm" ]] && source "${HOME}/.rvm/scripts/rvm"
  else
    export PATH="$(__path_filter "${PATH}" "rvm")"
  fi
else
  if [[ -z "${DCP_DISABLE_RBENV}" ]]; then
    if [[ -d "${HOME}/.rbenv/shims" ]]; then
      export RBENV_ROOT="${HOME}/.rbenv"
      [[ -d "${RBENV_ROOT}/bin" ]] && export PATH="${RBENV_ROOT}/bin:${PATH}"
    fi
    hash rbenv 2>/dev/null && eval "$(rbenv init -)"
  else
    export PATH="$(__path_filter "${PATH}" "rbenv")"
  fi
fi


#
# Final steps
#

# GPG Agent
if [[ -s "${HOME}/.gnupg/gpg-agent-info" && -S "${HOME}/.gnupg/S.gpg-agent.ssh" ]]; then
  source "${HOME}/.gnupg/gpg-agent-info"
  export GPG_AGENT_INFO
  export SSH_AUTH_SOCK
  export SSH_AGENT_PID
fi

# Base16 colors, if the script path has been set locally
[[ -s "${BASE16_SHELL}" && -z "${INSIDE_EMACS}" ]] && source "${BASE16_SHELL}"

# Another round of PATH deduplification after version managers load
if [[ -z "${DCP_DISABLE_MANAGERS}" ]]; then
  export PATH="$(__path_distinct "${PATH}")"
fi
