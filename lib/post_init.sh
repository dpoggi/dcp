#
# Add ~/.local/bin directory to PATH if available
#

if [[ -d "${HOME}/.local/bin" ]]; then
  export PATH="${HOME}/.local/bin:${PATH}"
fi


#
# BEGIN VERSION MANAGER SHENANIGANS
#

if [[ -n "${DCP_PREVENT_DISABLE}" ]]; then
  __unexport DCP_DISABLE_MANAGERS
  __unexport DCP_DISABLE_NVM
  __unexport DCP_DISABLE_OPAM
  __unexport DCP_DISABLE_PYENV
  __unexport DCP_DISABLE_RVM
  __unexport DCP_DISABLE_RBENV
  __unexport DCP_DISABLE_RUSTUP
  __unexport DCP_PREVENT_DISABLE
fi

if [[ -n "${DCP_DISABLE_MANAGERS}" ]]; then
  export DCP_DISABLE_NVM="true"
  export DCP_DISABLE_OPAM="true"
  export DCP_DISABLE_PYENV="true"
  export DCP_DISABLE_RVM="true"
  export DCP_DISABLE_RBENV="true"
  export DCP_DISABLE_RUSTUP="true"

  __unexport DCP_DISABLE_MANAGERS
fi


# rustup

if [[ -z "${DCP_DISABLE_RUSTUP}" ]]; then
  if [[ -d "${HOME}/.cargo" ]]; then
    export PATH="${HOME}/.cargo/bin:${PATH}"
  fi
else
  export PATH="$(__path_select "${PATH}" '$_ !~ /cargo/')"
fi


# OPAM

if [[ -z "${DCP_DISABLE_OPAM}" ]]; then
  if [[ "${DCP_SHELL}" = "bash" && -s "${HOME}/.opam/opam-init/init.sh" ]]; then
    . "${HOME}/.opam/opam-init/init.sh"
  elif [[ "${DCP_SHELL}" = "zsh" && -s "${HOME}/.opam/opam-init/init.zsh" ]]; then
    . "${HOME}/.opam/opam-init/init.zsh"
  fi
else
  export PATH="$(__path_select "${PATH}" '$_ !~ /opam/')"
fi


# nvm

if [[ -z "${DCP_DISABLE_NVM}" ]]; then
  if [[ -d "${HOME}/.nvm" ]]; then
    export NVM_DIR="${HOME}/.nvm"
  fi

  if [[ -s "${NVM_DIR}/nvm.sh" ]]; then
    . "${NVM_DIR}/nvm.sh"
  elif [[ -s /usr/local/opt/nvm/nvm.sh ]]; then
    . /usr/local/opt/nvm/nvm.sh
  fi
elif [[ -z "${DCP_DISABLE_NVM_NOFILTER}" ]]; then
  export PATH="$(__path_select "${PATH}" '$_ !~ /nvm/')"
fi


# pyenv + pyenv-virtualenv

if [[ -z "${DCP_DISABLE_PYENV}" ]]; then
  if [[ -d "${HOME}/.pyenv/shims" ]]; then
    export PYENV_ROOT="${HOME}/.pyenv"

    if [[ -d "${PYENV_ROOT}/bin" ]]; then
      export PATH="${PYENV_ROOT}/bin:${PATH}"
    fi
  fi

  if hash pyenv 2> /dev/null; then
    eval "$(pyenv init -)"
  fi

  if hash pyenv-virtualenv-init 2> /dev/null; then
    export PYENV_VIRTUALENV_DISABLE_PROMPT="1"
    eval "$(pyenv-virtualenv-init -)"
  fi
else
  export PATH="$(__path_select "${PATH}" '$_ !~ /pyenv/')"
fi


# rbenv or rvm (if you have to, I guess)

if [[ -d "${HOME}/.rvm" ]]; then
  if [[ -z "${DCP_DISABLE_RVM}" ]]; then
    export PATH="${PATH}:${HOME}/.rvm/bin"

    if [[ -s "${HOME}/.rvm/scripts/rvm" ]]; then
      . "${HOME}/.rvm/scripts/rvm"
    fi
  else
    export PATH="$(__path_select "${PATH}" '$_ !~ /rvm/')"
  fi
else
  if [[ -z "${DCP_DISABLE_RBENV}" ]]; then
    if [[ -d "${HOME}/.rbenv/shims" ]]; then
      export RBENV_ROOT="${HOME}/.rbenv"

      if [[ -d "${RBENV_ROOT}/bin" ]]; then
        export PATH="${RBENV_ROOT}/bin:${PATH}"
      fi
    fi

    if hash rbenv 2> /dev/null; then
      eval "$(rbenv init -)"
    fi
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

# Base16 colors, if the script path has been set locally

if [[ -s "${BASE16_SHELL}" && -z "${INSIDE_EMACS}" ]]; then
  . "${BASE16_SHELL}"
fi

# Another round of PATH deduplication after version managers load

export PATH="$(__path_distinct "${PATH}")"
