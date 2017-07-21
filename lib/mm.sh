# MetaMan
# mm.sh - tying it all together
#
# Copyright (C) 2017 Dan Poggi
#
# This software may be modified and distributed under the terms
# of the MIT license. See the LICENSE file for details.

MM_TOOLS=(cargo nvm pyenv rvm rbenv)

readonly MM_TOOLS

for tool in "${MM_TOOLS[@]}"; do
  tool_upper="$(__strtoupper "${tool}")"

  declare +x "MM_DISABLE_${tool_upper}"

  . "${DCP}/lib/mm/${tool}.sh"
done
unset tool tool_upper

. "${DCP}/lib/mm/meta.sh"

. "${DCP}/lib/mm/cli.sh"

mm_on --all --soft
