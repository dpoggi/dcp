# MetaMan
# rvm.sh - implements meta.sh for rvm
#
# Copyright (C) 2017 Dan Poggi
#
# This software may be modified and distributed under the terms
# of the MIT license. See the LICENSE file for details.

__mm_rvm_is_loaded() {
  __is_function rvm
}

__mm_rvm_is_installed() {
  [[ -r "$(__mm_rvm_get_dir)/scripts/rvm" ]]
}

__mm_rvm_load() {
  export RVM_DIR="$(__mm_rvm_get_dir)"
  . "${RVM_DIR}/scripts/rvm"
}

__mm_rvm_get_dir() {
  printf "%s" "${RVM_DIR:-${HOME}/.rvm}"
}
