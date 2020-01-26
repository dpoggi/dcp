# MetaMan
# mm.sh - tying it all together
#
# Copyright (C) 2017-2020 Dan Poggi
#
# This software may be modified and distributed under the terms
# of the MIT license. See the LICENSE file for details.

MM_TOOLS=(cargo nvm pyenv rvm rbenv)
MM_TOOLS_FOR_USAGE="($(__ary_join ' | ' "${MM_TOOLS[@]}"))"

readonly MM_TOOLS MM_TOOLS_FOR_USAGE

for tool in "${MM_TOOLS[@]}"; do
  tool_upper="$(__strtoupper "${tool}")"

  declare +x "MM_DISABLE_${tool_upper}"

  if __is_true "MM_DISABLE_${tool_upper}"; then
    while IFS=$'\n' read -r var_name; do
      __unexport "${var_name}"
    done < <(__export_select_re "^${tool_upper}_")

    unset var_name

    export PATH="$(__path_reject_re "${PATH}" "${tool}")"
  fi

  . "${DCP}/lib/mm/${tool}.sh"
done

unset tool tool_upper

. "${DCP}/lib/mm/meta.sh"
. "${DCP}/lib/mm/cli.sh"

mm_on --all --soft
