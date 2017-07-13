#
# Add ~/.local/bin directory to PATH if available
#

if [[ -d "${HOME}/.local/bin" ]]; then
  export PATH="${HOME}/.local/bin:${PATH}"
fi


#
# BEGIN VERSION MANAGER SHENANIGANS
#

. "${DCP}/lib/version_managers.sh"

if [[ -n "${DCP_PREVENT_DISABLE}" ]]; then
  __unexport DCP_PREVENT_DISABLE
  __unexport DCP_DISABLE_MANAGERS

  for version_manager in "${DCP_VERSION_MANAGERS[@]}"; do
    __unexport "DCP_DISABLE_${version_manager}"
  done
  unset version_manager
fi

if [[ -n "${DCP_DISABLE_MANAGERS}" ]]; then
  for version_manager in "${DCP_VERSION_MANAGERS[@]}"; do
    export DCP_DISABLE_${version_manager}=true
  done
  unset version_manager

  __unexport DCP_DISABLE_MANAGERS
fi


# rustup

if [[ -z "${DCP_DISABLE_RUSTUP}" ]]; then
  enable_rustup
else
  __path_scrub 'cargo'
fi


# OPAM

if [[ -z "${DCP_DISABLE_OPAM}" ]]; then
  enable_opam
else
  __path_scrub 'opam'
fi


# nvm

if [[ -z "${DCP_DISABLE_NVM}" ]]; then
  enable_nvm
else
  __path_scrub 'nvm'
fi


# pyenv + pyenv-virtualenv

if [[ -z "${DCP_DISABLE_PYENV}" ]]; then
  enable_pyenv
else
  __path_scrub 'pyenv'
fi


# rbenv or rvm (if you have to, I guess)

if [[ -d "${HOME}/.rvm" ]]; then
  if [[ -z "${DCP_DISABLE_RVM}" ]]; then
    enable_rvm
  else
    __path_scrub 'rvm'
  fi
else
  if [[ -z "${DCP_DISABLE_RBENV}" ]]; then
    enable_rbenv
  else
    __path_scrub 'rbenv'
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
