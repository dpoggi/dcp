DCP_VERSION_MANAGERS=(RUSTUP OPAM NVM PYENV RVM RBENV)
readonly DCP_VERSION_MANAGERS

__path_scrub() {
  if [[ -z "$1" ]]; then
    return 1
  fi
  export PATH="$(__path_select "${PATH}" "\$_ !~ /$1/")"
}

enable_rustup() {
  if [[ -d "${HOME}/.cargo" ]]; then
    export PATH="${HOME}/.cargo/bin:${PATH}"
  fi
}

enable_opam() {
  if [[ "${DCP_SHELL}" = "bash" && -s "${HOME}/.opam/opam-init/init.sh" ]]; then
    . "${HOME}/.opam/opam-init/init.sh"
  elif [[ "${DCP_SHELL}" = "zsh" && -s "${HOME}/.opam/opam-init/init.zsh" ]]; then
    . "${HOME}/.opam/opam-init/init.zsh"
  fi
}

enable_nvm() {
  if [[ -d "${HOME}/.nvm" ]]; then
    export NVM_DIR="${HOME}/.nvm"
  fi

  if [[ -s "${NVM_DIR}/nvm.sh" ]]; then
    . "${NVM_DIR}/nvm.sh"
  elif [[ -s "/usr/local/opt/nvm/nvm.sh" ]]; then
    . /usr/local/opt/nvm/nvm.sh
  fi
}

enable_pyenv() {
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
}

enable_rvm() {
  export PATH="${PATH}:${HOME}/.rvm/bin"

  if [[ -s "${HOME}/.rvm/scripts/rvm" ]]; then
    . "${HOME}/.rvm/scripts/rvm"
  fi
}

enable_rbenv() {
  if [[ -d "${HOME}/.rbenv/shims" ]]; then
    export RBENV_ROOT="${HOME}/.rbenv"

    if [[ -d "${RBENV_ROOT}/bin" ]]; then
      export PATH="${RBENV_ROOT}/bin:${PATH}"
    fi
  fi

  if hash rbenv 2> /dev/null; then
    eval "$(rbenv init -)"
  fi
}
