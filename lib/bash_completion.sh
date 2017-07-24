__bash_comp_is_loaded() { [[ -n "${BASH_COMPLETION_COMPAT_DIR}" ]]; }

__bash_comp_is_installed() {
  [[ -r "/usr/local/etc/bash_completion" || -r "/etc/bash_completion" ]]
}

__bash_comp_load_dir() {
  local pattern='(?:~$|\.bak$|\.swp$|^#.*#$|\.dpkg.*$|\.rpm(?:new|orig|save)$|^Makefile)'
  local completion

  while IFS='' read -d '' -r completion; do
    if basename "${completion}" | grep -qE "${pattern}"; then
      continue
    fi

    . "${completion}"
  done < <(find "$1" -mindepth 1 -maxdepth 1 ! -type d -print0 2>/dev/null)
}

if ! __bash_comp_is_loaded && __bash_comp_is_installed; then
  if [[ -r "${XDG_CONFIG_HOME:-${HOME}/.config}/bash_completion" ]]; then
    . "${XDG_CONFIG_HOME:-${HOME}/.config}/bash_completion"
  fi

  if [[ -r "/usr/local/etc/bash_completion" ]]; then
    . /usr/local/etc/bash_completion
  elif [[ -r "/etc/bash_completion" ]]; then
    . /etc/bash_completion
  fi
fi

if __bash_comp_is_loaded; then
  readonly XDG_BASH_COMPLETION_D="${XDG_CONFIG_HOME:-${HOME}/.config}/bash_completion.d"

  if [[ ! -e "${XDG_BASH_COMPLETION_D}" ]]; then
    mkdir -p "${XDG_BASH_COMPLETION_D}"
  fi

  __bash_comp_load_dir "${DCP}/share/completions/bash"
  __bash_comp_load_dir "${XDG_BASH_COMPLETION_D}"
fi

unset -f __bash_comp_is_loaded __bash_comp_is_installed __bash_comp_load_dir
