# MetaMan
# nvm.sh - implements meta.sh for nvm
#
# Copyright (C) 2017 Dan Poggi
#
# This software may be modified and distributed under the terms
# of the MIT license. See the LICENSE file for details.

__mm_nvm_is_loaded() {
  __is_function nvm
}

__mm_nvm_is_installed() {
  [[ -r "$(__mm_nvm_get_dir)/nvm.sh" || -r "/usr/local/opt/nvm/nvm.sh" ]]
}

__mm_nvm_load() {
  export NVM_DIR="$(__mm_nvm_get_dir)"

  if [[ -r "${NVM_DIR}/nvm.sh" ]]; then
    . "${NVM_DIR}/nvm.sh"
  elif [[ -r "/usr/local/opt/nvm/nvm.sh" ]]; then
    . "/usr/local/opt/nvm/nvm.sh"
  fi
}

__mm_nvm_is_comp_loaded() {
  __is_function __nvm
}

__mm_nvm_load_comp() {
  if [[ -r "${NVM_DIR}/bash_completion" ]]; then
    if __is_bash; then
      ln -snf "${NVM_DIR}/bash_completion" "${DCP_BASH_COMPLETION_D}/nvm"
    fi

    . "${NVM_DIR}/bash_completion"
  elif [[ -r "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ]]; then
    . /usr/local/opt/nvm/etc/bash_completion.d/nvm
  fi
}

__mm_nvm_get_dir() {
  printf "%s" "${NVM_DIR:-${HOME}/.nvm}"
}
