# MetaMan
# mm.sh - tying it all together
#
# Copyright (C) 2017-2020 Dan Poggi
#
# This software may be modified and distributed under the terms
# of the MIT license. See the LICENSE file for details.

__mm_tools=( cargo nvm pyenv rvm rbenv )
__mm_usage_tools="$(__ary_join ' | ' "${__mm_tools[@]}")"

readonly __mm_tools __mm_usage_tools

for tool in "${__mm_tools[@]}"; do
  declare +x "__mm_disable_${tool}"

  if __is_true "__mm_disable_${tool}"; then
    if [[ " ${__mm_force_load} " != *" ${tool} "* ]]; then
      while IFS=$'\n' read -r var_name; do
        __unexport "${var_name}"
      done < <(__export_select_re "^$(__strtoupper "${tool}")_")

      unset var_name

      export PATH="$(__path_reject_re "${PATH}" "${tool}")"
    else
      unset "__mm_disable_${tool}"
    fi
  fi

  . "${DCP}/lib/mm/${tool}.sh"
done

unset tool

__unexport __mm_force_load

. "${DCP}/lib/mm/meta.sh"
. "${DCP}/lib/mm/cli.sh"

mm_on --all --soft
