# MetaMan
# cargo.sh - implements meta.sh for cargo
#
# Copyright (C) 2017 Dan Poggi
#
# This software may be modified and distributed under the terms
# of the MIT license. See the LICENSE file for details.

__mm_cargo_is_loaded() {
  __is_command cargo \
    && [[ -n "$(__path_select_str "${PATH}" "${CARGO_HOME}/bin")" ]]
}

__mm_cargo_is_installed() {
  [[ -x "$(__mm_cargo_get_home)/bin/cargo" ]] || __is_command cargo
}

__mm_cargo_load() {
  export CARGO_HOME="$(__mm_cargo_get_home)"
  export PATH="${CARGO_HOME}/bin:${PATH}"
}

__mm_cargo_is_comp_loaded() {
  ! __is_command rustup || (__is_function _cargo && __is_function _rustup)
}

__mm_cargo_load_comp_zsh() {
  rustup completions zsh > "${DCP_ZSH_FUNCTIONS}/_rustup"

  local toolchain_dir="$(__mm_cargo_get_toolchain_dir)"

  if [[ -d "${toolchain_dir}" ]]; then
    cp "${toolchain_dir}/share/zsh/site-functions/_cargo" \
       "${DCP_ZSH_FUNCTIONS}/_cargo"
  fi

  cat >&2 <<-EOT
Completions for cargo and rustup have been installed. To activate, restart the
current shell: \`${DCP_SHELL_INVOCATION}'
EOT
}

__mm_cargo_load_comp_bash() {
  rustup completions bash > "${DCP_BASH_COMPLETION_D}/rustup.bash-completion"
  . "${DCP_BASH_COMPLETION_D}/rustup.bash-completion"

  local toolchain_dir="$(__mm_cargo_get_toolchain_dir)"

  if [[ -d "${toolchain_dir}" ]]; then
    cp "${toolchain_dir}/etc/bash_completion.d/cargo" \
       "${DCP_BASH_COMPLETION_D}/cargo"
    . "${DCP_BASH_COMPLETION_D}/cargo"
  fi
}

__mm_cargo_get_home() {
  printf "%s" "${CARGO_HOME:-${HOME}/.cargo}"
}

__mm_cargo_get_toolchain_dir() {
  local toolchain="$(rustup toolchain list | sed -e '/(default)$/!d' \
                                                 -e 's/[ ]*(default)$//')"
  printf "%s/toolchains/%s" \
         "${RUSTUP_HOME:-${HOME}/.rustup}" \
         "${toolchain}"
}
