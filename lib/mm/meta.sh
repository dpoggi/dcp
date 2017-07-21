# MetaMan
# meta.sh - "making sense" of eval dumbitude
#
# Copyright (C) 2017 Dan Poggi
#
# This software may be modified and distributed under the terms
# of the MIT license. See the LICENSE file for details.

__mm_is_loaded() { eval "__mm_$1_is_loaded"; }

__mm_is_installed() { eval "__mm_$1_is_installed"; }

__mm_load() { eval "__mm_$1_load"; }

__mm_is_comp_loaded() {
  if __is_function "__mm_$1_is_comp_loaded_${DCP_SHELL}"; then
    eval "__mm_$1_is_comp_loaded_${DCP_SHELL}"
  elif __is_function "__mm_$1_is_comp_loaded"; then
    eval "__mm_$1_is_comp_loaded"
  fi
}

__mm_load_comp() {
  if __is_function "__mm_$1_load_comp_${DCP_SHELL}"; then
    eval "__mm_$1_load_comp_${DCP_SHELL}"
  elif __is_function "__mm_$1_load_comp"; then
    eval "__mm_$1_load_comp"
  fi
}
