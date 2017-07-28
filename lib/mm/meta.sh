# MetaMan
# meta.sh - "making sense" of dynamic dispatch dumbitude
#
# Copyright (C) 2017 Dan Poggi
#
# This software may be modified and distributed under the terms
# of the MIT license. See the LICENSE file for details.

__mm_is_comp_loaded() {
  if __is_function "__mm_$1_is_comp_loaded_${DCP_SHELL}"; then
    "__mm_$1_is_comp_loaded_${DCP_SHELL}"
  elif __is_function "__mm_$1_is_comp_loaded"; then
    "__mm_$1_is_comp_loaded"
  fi
}

__mm_load_comp() {
  if __is_function "__mm_$1_load_comp_${DCP_SHELL}"; then
    "__mm_$1_load_comp_${DCP_SHELL}"
  elif __is_function "__mm_$1_load_comp"; then
    "__mm_$1_load_comp"
  fi
}
