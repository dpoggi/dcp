# MetaMan
# cargo.sh - implements meta.sh for cargo
#
# Copyright (C) 2017 Dan Poggi
#
# This software may be modified and distributed under the terms
# of the MIT license. See the LICENSE file for details.

# Cargo always reports as unloaded, so that it will be loaded, so that PATH
# stays in the proper order. Harmless since we guarantee PATH will be deduped.
__mm_cargo_is_loaded() { false; }

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
  rustup completions zsh >"${USER_ZSH_FUNCTIONS}/_rustup"

  local toolchain_dir="$(__mm_cargo_get_toolchain_dir)"

  if [[ -d "${toolchain_dir}" ]]; then
    cp "${toolchain_dir}/share/zsh/site-functions/_cargo" \
       "${USER_ZSH_FUNCTIONS}/_cargo"
  fi

  cat >&2 <<EOT
Completions for cargo and rustup have been installed. To activate, restart the
current shell: \`${DCP_SHELL_EXEC_CMD[*]}'
EOT
}

__mm_cargo_load_comp_bash() {
  rustup completions bash >"${USER_BASH_COMPLETION_D}/rustup.bash-completion"
  . "${USER_BASH_COMPLETION_D}/rustup.bash-completion"

  local toolchain_dir="$(__mm_cargo_get_toolchain_dir)"

  if [[ -d "${toolchain_dir}" ]]; then
    cp "${toolchain_dir}/etc/bash_completion.d/cargo" \
       "${USER_BASH_COMPLETION_D}/cargo"
    . "${USER_BASH_COMPLETION_D}/cargo"
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
