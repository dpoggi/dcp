COMP_LOAD_PATHS=(
  "/opt/homebrew/etc/profile.d/bash_completion.sh"
  "/usr/local/etc/profile.d/bash_completion.sh"
  "/usr/local/etc/bash_completion"
  "/etc/bash_completion"
  "/usr/share/bash-completion/bash_completion"
)

__comp_is_loaded() {
  [[ -n "${BASH_COMPLETION_COMPAT_DIR}" ]]
}

__comp_is_installed() {
  local load_path
  for load_path in "${COMP_LOAD_PATHS[@]}"; do
    if [[ -r "${load_path}" ]]; then
      return
    fi
  done
  return 1
}

__comp_is_comp_ignored() {
  local comp_name
  comp_name="$(basename "$1")"
  grep -q -E \
    '(?:~$|\.bak$|\.swp$|^#.*#$|\.dpkg.*$|\.rpm(?:new|orig|save)$|^Makefile)' \
    <<<"${comp_name}" 2>/dev/null
}

__comp_load_dir() {
  local comp
  while IFS='' read -d '' -r comp; do
    if ! __comp_is_comp_ignored "${comp}" && [[ -r "${comp}" ]]; then
      . "${comp}"
    fi
  done < <(
    find "$1" \
      -mindepth 1 \
      -maxdepth 1 \
      ! -type d \
      -print0 2>/dev/null
  )
}

if __comp_is_installed; then
  if ! __comp_is_loaded; then
    for COMP_LOAD_PATH in "${COMP_LOAD_PATHS[@]}"; do
      if [[ -r "${COMP_LOAD_PATH}" ]]; then
        . "${COMP_LOAD_PATH}"
        break
      fi
    done
    unset COMP_LOAD_PATH
  fi

  if __comp_is_loaded; then
    BASH_COMPLETION_USER_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/bash_completion.d"
    if [[ ! -e "${BASH_COMPLETION_USER_DIR}" ]]; then
      mkdir -p "${BASH_COMPLETION_USER_DIR}"
    fi

    __comp_load_dir "${DCP}/etc/bash_completion.d"
    __comp_load_dir "${BASH_COMPLETION_USER_DIR}"
  fi
fi

unset -f \
  __comp_is_loaded \
  __comp_is_installed \
  __comp_is_comp_ignored \
  __comp_load \
  __comp_load_dir

unset \
  COMP_LOAD_PATHS
