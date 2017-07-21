# MetaMan
# rbenv.sh - implements meta.sh for rbenv
#
# Copyright (C) 2017 Dan Poggi
#
# This software may be modified and distributed under the terms
# of the MIT license. See the LICENSE file for details.

__mm_rbenv_is_loaded() {
  __is_function rbenv
}

__mm_rbenv_is_installed() {
  ! __mm_rvm_is_installed \
    && (__is_command rbenv || [[ -x "$(__mm_rbenv_get_root)/bin/rbenv" ]])
}

__mm_rbenv_load() {
  export RBENV_ROOT="$(__mm_rbenv_get_root)"

  if [[ -d "${RBENV_ROOT}/bin" ]]; then
    export PATH="${RBENV_ROOT}/bin:${PATH}"
  fi

  eval "$(rbenv init -)"
}

__mm_rbenv_get_root() {
  printf "%s" "${RBENV_ROOT:-${HOME}/.rbenv}"
}
