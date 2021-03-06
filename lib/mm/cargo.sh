# MetaMan
# cargo.sh - implements meta.sh for cargo
#
# Copyright (C) 2017 Dan Poggi
#
# This software may be modified and distributed under the terms
# of the MIT license. See the LICENSE file for details.

__mm_cargo_is_loaded() {
  __is_command rustup
}

__mm_cargo_is_installed() {
  [[ -x "${CARGO_HOME:-${HOME}/.cargo}/bin/cargo" ]] || __is_command cargo
}

__mm_cargo_load() {
  export CARGO_HOME="${CARGO_HOME:-${HOME}/.cargo}"
  export PATH="${CARGO_HOME}/bin:${PATH}"
}

__mm_cargo_unload() {
  export PATH="$(__path_reject_str "${PATH}" "${CARGO_HOME}/bin")"
  __unexport CARGO_HOME
}

__mm_cargo_is_comp_loaded() {
#  ! __is_command rustup || { __is_function _cargo && __is_function _rustup; }
  ! __is_command rustup || __is_function _rustup
}

__mm_cargo_load_comp_zsh() {
  local flag="false"

  if [[ ! -s "${USER_ZSH_FUNCTIONS}/_rustup" ]]; then
    rustup completions zsh >"${USER_ZSH_FUNCTIONS}/_rustup"
    flag="true"
  fi

  if [[ ! -s "${USER_ZSH_FUNCTIONS}/_cargo" ]]; then
    local toolchain_dir
    toolchain_dir="$(__mm_cargo_get_toolchain_dir)"

    if [[ -d "${toolchain_dir}" ]]; then
      cp "${toolchain_dir}/share/zsh/site-functions/_cargo" \
         "${USER_ZSH_FUNCTIONS}/_cargo"
      flag="true"
    fi
  fi

  if "${flag}"; then
    cat >&2 <<EOT
Completions for cargo and rustup have been installed. To activate, restart the
current shell: \`${DCP_SHELL_EXEC_CMD[*]}'
EOT
  fi
}

__mm_cargo_load_comp_bash() {
  rustup completions bash >"${BASH_COMPLETION_USER_DIR}/rustup.bash-completion"
  . "${BASH_COMPLETION_USER_DIR}/rustup.bash-completion"

  local toolchain_dir="$(__mm_cargo_get_toolchain_dir)"

  if [[ -d "${toolchain_dir}" ]]; then
    cp "${toolchain_dir}/etc/bash_completion.d/cargo" "${BASH_COMPLETION_USER_DIR}/cargo"

    . "${BASH_COMPLETION_USER_DIR}/cargo"
  fi
}

__mm_cargo_get_toolchain_dir() {
  local toolchain="$(rustup toolchain list | sed -e '/(default)$/!d' \
                                                 -e 's/[ ]*(default)$//')"
  printf "%s/toolchains/%s" \
         "${RUSTUP_HOME:-${HOME}/.rustup}" \
         "${toolchain}"
}
