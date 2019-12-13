#
# Xcode aliases
#

# Open Xcode for current folder (prefers workspace to project)
xc() {
  local xcode_app
  if ! xcode_app="$(__get_xcode_app)"; then
    xcode_app="Xcode"
  fi
  /usr/bin/open -a "${xcode_app}" "${1:-.}"
}

# Dammit Xcode (delete derived data twice a day for entire career as needed)
fuxcode() {
  __check_dt_not_running || return 1

  if [[ -d "${HOME}/Library/Developer/Xcode/DerivedData" ]]; then
    rm -rf "${HOME}/Library/Developer/Xcode/DerivedData"
  fi
}

# Dammit CoreSimulator (kill simulator service twice a day for entire career as needed)
fucoresim() {
  __check_dt_not_running || return 1
  /bin/launchctl bootout "user/${UID}/com.apple.CoreSimulator.CoreSimulatorService"
}

# Dammit Interface Builder (ibtool)
fuibtool() {
  __check_dt_not_running || return 1
  /usr/bin/pkill -KILL -x -U "${UID}" "ibtoold"
}

# Verify Xcode installation
haxcode() {
  local xcode_app
  if ! xcode_app="$(__get_xcode_app)"; then
    printf 'Error: Command Line Tools selected, or Xcode not installed.\n'
    return 1
  fi

  /usr/sbin/spctl --assess --verbose "${xcode_app}"
}

__check_dt_not_running() {
  if /usr/bin/pgrep -x -U "${UID}" "Simulator" >/dev/null 2>&1; then
    printf >&2 'Error: Simulator is running.\n'
    return 1
  fi
  if /usr/bin/pgrep -x -U "${UID}" "Xcode" >/dev/null 2>&1; then
    printf >&2 'Error: Xcode is running.\n'
    return 1
  fi
}

# Get the path of the currently selected Xcode.
__get_xcode_app() {
  local developer_dir
  if ! developer_dir="$(/usr/bin/xcode-select --print-path 2>/dev/null)"; then
    return 1
  fi
  if [[ "${developer_dir}" != *".app/Contents/Developer" ]]; then
    return 1
  fi
  printf '%s\n' "${developer_dir%"/Contents/Developer"}"
}

#
# Homebrew - fully update/upgrade, clean up the mess, optionally
#            install something in between. Boop!
#

boop() {
  __boop_check_pyenv

  local err

  brew update; err="$?"
  ((err == 0)) || return "${err}"

  brew upgrade; err="$?"
  ((err == 0)) || return "${err}"

  if (($# > 0)); then
    brew install "$@"; err="$?"
    ((err == 0)) || return "${err}"
  fi

  brew cleanup --prune=all -s
}

boop_cask() {
  (($# > 0)) || return 1

  local err

  brew update; err="$?"
  ((err == 0)) || return "${err}"

  brew cask install "$@"; err="$?"
  ((err == 0)) || return "${err}"

  brew cleanup --prune=all -s
}

__boop_check_pyenv() {
  if ! __is_function mm_off; then
    return
  fi
  if [[ -z "$(__path_select_re "${PATH}" 'rbenv|rvm|pyenv|nvm')" ]]; then
    return
  fi

  cat >&2 <<EOT
rbenv, rvm, pyenv, and/or nvm found in PATH. This can break installing or
upgrading software from Homebrew. Run \`mm_off -a\` now to restart this
EOT
  printf >&2 'shell without it/them (y/n)? '

  local confirmation
  read -r confirmation
  if [[ "${confirmation}" =~ ^[Yy] ]]; then
    printf >&2 '\nRestarting the shell. Please run this command again.\n'
    mm_off -a
  fi
}

# Code signing helper for Homebrew binaries (notably GDB)

if [[ -s "${DCP_CONFIG_DIR}/brew_codesign.sha1" ]]; then
  brew_codesign() {
    local target fingerprint

    target="$1"
    if __is_command realpath; then
      target="$(realpath -q "${target}")"
    fi

    if ! __is_macho_bundle "${target}" && ! __is_macho_file "${target}"; then
      printf >&2 'Error: argument is not a Mach-O bundle or binary file.\n'
      return 1
    fi

    fingerprint="$(<"${DCP_CONFIG_DIR}/brew_codesign.sha1")"

    /usr/bin/codesign --force --sign "${fingerprint}" "${target}"
  }

  __is_macho_bundle() {
    local bundle_name

    bundle_name="$(basename "$1")"
    bundle_name="${bundle_name%%.*}"

    if [[ ! -d "$1" ]]; then
      return 1
    fi

    [[ -d "$1/Contents" ]] || __is_macho_file "$1/${bundle_name}"
  }

  __is_macho_file() {
    local output
    output="$(file -b "$1" 2>/dev/null)"
    [[ "${output}" = "Mach-O"* ]]
  }
fi

#
# Quickly compute and copy a file's hash to the clipboard
#

copy_md5() {
  if [[ ! -f "$1" ]]; then
    printf >&2 'Argument is not a file.\n'
    return 1
  fi
  
  local sum="$(/sbin/md5 -q "$1")"
  printf '%s' "${sum}" | pbcopy
  printf '%s\n' "${sum}"
}

copy_sha1() { __copy_sha 1 "$1"; }
copy_sha256() { __copy_sha 256 "$1"; }
copy_sha384() { __copy_sha 384 "$1"; }

__copy_sha() {
  if [[ ! -f "$2" ]]; then
    printf >&2 'Argument is not a file.\n'
    return 1
  fi

  local sum="$(/usr/bin/shasum -a "$1" "$2" | cut -d ' ' -f 1)"
  printf '%s' "${sum}" | pbcopy
  printf '%s\n' "${sum}"
}

# Fix obnoxious bug with macOS zsh completion for /usr/bin/du if coreutils is
# installed via Homebrew.
if __is_zsh && [[ -x "/usr/local/opt/coreutils/bin/gdu" ]]; then
  du() { /usr/local/opt/coreutils/bin/gdu "$@"; }
fi

#
# System-level resets... these come in handy.
#

# Set hostname on (at least) Mojave and up
set_hostname() {
  if [[ -z "$1" ]]; then
    return 1
  fi

  sudo -H scutil --set ComputerName "$1"
  sudo -H scutil --set LocalHostName "$1"
  sudo -H scutil --set HostName "$1"
}

# Reset "Open With..." menus after connecting a drive with applications on it
reset_launch_services() {
  local framework_path="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework"

  "${framework_path}"/Support/lsregister -kill -r \
                                         -domain local \
                                         -domain system \
                                         -domain user

  killall Finder
}

# Flush DNS cache and reset mDNSResponder
reset_dns_cache() {
  printf >&2 'Flushing the DNS cache (enter your user password if prompted)...\n'

  if ! __is_file discoveryutil; then
    # Sane versions of macOS
    sudo -H dscacheutil -flushcache
    sudo -H killall -HUP mDNSResponder
  else
    # OS X 10.9 - 10.10.3 (rest in pieces, discoveryd)
    sudo -H discoveryutil mdnsflushcache
    sudo -H discoveryutil udnsflushcache
  fi
}

# Clear Quick Look's file locks (so you can empty the trash)
reset_quick_look() {
  qlmanage -r
}

#
# Just launchd things (tm)
#

# Convenience wrapper for globally "exporting" a variable. Similar to setting
# environment variables in the Control Panel on Windows. Seen by apps like
# IntelliJ that pick up on certain vars: JAVA_HOME, etc.
launchd_export() {
  while (($# > 0)); do
    launchctl setenv "$1" "$(__valueof "$1")"
    shift
  done
}

# launchctl wrapper for apsd (Apple Push Service: Messages.app, etc.)
apsctl() {
  "${DCP}/libexec/lctl.sh" \
    apsctl \
    system /System/Library/LaunchDaemons/com.apple.apsd.plist \
    "$(__lctl_protected_action "$1")"
}

# launchctl wrapper for CoreAudio (because sometimes there be dragons)
coreaudioctl() {
  "${DCP}/libexec/lctl.sh" \
    coreaudioctl \
    system /System/Library/LaunchDaemons/com.apple.audio.coreaudiod.plist \
    "$1"
}

# launchctl wrapper for bluetoothd
bluetoothctl() {
  "${DCP}/libexec/lctl.sh" \
    bluetoothctl \
    system /System/Library/LaunchDaemons/com.apple.bluetoothd.plist \
    "$(__lctl_protected_action "$1")"
}

# launchctl wrapper for cfprefsd agent (clear file locks / empty the trash)
cfprefsctl() {
  "${DCP}/libexec/lctl.sh" \
    cfprefsctl \
    user /System/Library/LaunchAgents/com.apple.cfprefsd.xpc.agent.plist \
    "$(__lctl_protected_action "$1")"
}

# "action transformer" for protected services that can't be stopped traditionally
__lctl_protected_action() {
  case "$1" in
    stop)     printf 'unstoppable\n' ;;
    restart)  printf 'kickstart\n' ;;
    *)        printf '%s\n' "$1"
  esac
}

# gpgconf wrapper for gpg-agent, if installed via Homebrew

if [[ -h "/usr/local/opt/gnupg" ]]; then
  gpgagentctl() {
    if [[ "$1" = "stop" || "$1" = "restart" ]]; then
      /usr/local/opt/gnupg/bin/gpgconf --kill "gpg-agent"

      if /usr/bin/pgrep -q -x -U "${UID}" "gpg-agent" 2>/dev/null; then
        /usr/bin/pkill -KILL -x -U "${UID}" "gpg-agent"
      fi
    fi

    if [[ "$1" != "stop" ]]; then
      /usr/local/opt/gnupg/bin/gpgconf --launch "gpg-agent"
    fi
  }
fi

# `brew services' wrappers for chunkwm, khd, and kwm if installed via Homebrew

if [[ -d "/usr/local/opt/chunkwm" ]]; then
  chunkwmctl() { __brewctl koekeishiya/formulae/chunkwm "$@"; }
fi
if [[ -d "/usr/local/opt/khd" ]]; then
  khdctl() { __brewctl koekeishiya/formulae/khd "$@"; }
fi
if [[ -d "/usr/local/opt/kwm" ]]; then
  kwmctl() { __brewctl koekeishiya/formulae/kwm "$@"; }
fi

__brewctl() {
  (($# > 1)) || return 1
  local formula="$1"; shift
  brew services "$@" "${formula}"
}

# htop(1) should generally be run as root on macOS
if [[ -x "/usr/local/opt/htop/bin/htop" ]]; then
  htop() { sudo /usr/local/opt/htop/bin/htop "$@"; }
fi
