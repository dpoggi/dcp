# MetaMan
# pyenv.sh - implements meta.sh for pyenv
#
# Copyright (C) 2017 Dan Poggi
#
# This software may be modified and distributed under the terms
# of the MIT license. See the LICENSE file for details.

__mm_pyenv_is_loaded() {
  __is_function pyenv
}

__mm_pyenv_is_installed() {
  __is_command pyenv || [[ -x "$(__mm_pyenv_get_root)/bin/pyenv" ]]
}

__mm_pyenv_load() {
  export PYENV_ROOT="$(__mm_pyenv_get_root)"

  if [[ -d "${PYENV_ROOT}/bin" ]]; then
    export PATH="${PYENV_ROOT}/bin:${PATH}"
  fi

  eval "$(pyenv init -)"

  if ! __is_command pyenv-virtualenv-init; then
    return
  fi

  export PYENV_VIRTUALENV_DISABLE_PROMPT="1"

  eval "$(pyenv-virtualenv-init -)"
}

__mm_pyenv_get_root() {
  printf "%s" "${PYENV_ROOT:-${HOME}/.pyenv}"
}
