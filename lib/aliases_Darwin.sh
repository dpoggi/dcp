#
# Xcode aliases
#

# Open Xcode for current folder (prefers workspace to project)
xc() {
  open -a "/Applications/Xcode.app" "${1:-.}"
}
# Same for Xcode beta versions (has __nothing__ to do with X11 :o)
xcb() {
  open -a "/Applications/Xcode-beta.app" "${1:-.}"
}
# Dammit Xcode (delete derived data twice a day for entire career as needed)
fuxcode() {
  rm -rf "${HOME}/Library/Developer/Xcode/DerivedData"
}
# Verify Xcode installation
haxcode() {
  spctl --assess --verbose "/Applications/Xcode.app"
}


#
# Homebrew - fully update/upgrade, clean up the mess, optionally
#            install something in between. Boop!
#

__boop_check_pyenv() {
  if ! __is_function mm_off; then
    return
  fi

  if [[ -z "$(__path_select_re "${PATH}" 'rbenv|rvm|pyenv|nvm')" ]]; then
    return
  fi

  cat >&2 <<-EOT
rbenv, rvm, pyenv, and/or nvm found in PATH. This will break installing or
upgrading Vim and/or Yarn from Homebrew. Run \`mm_off -a' now to restart this
EOT

  printf >&2 "shell without it/them (y/n)? "

  read -r

  if [[ "${REPLY}" = y* || "${REPLY}" = Y* ]]; then
    printf >&2 "\nRestarting the shell. Please run this command again.\n"
    mm_off -a
  fi
}

__boop_ruby() {
  if [[ "${DCP_BOOP_LINK_RUBY}" = "true" ]]; then
    brew "$1" ruby
  fi
}

boop() {
  __boop_check_pyenv

  __boop_ruby link

  if ! brew update; then
    return 1
  fi

  brew upgrade

  if ! brew upgrade; then
    return 1
  fi

  if [[ "$#" -gt "0" ]]; then
    if ! brew install "$@"; then
      return 1
    fi
  fi

  __boop_ruby unlink

  brew cleanup --prune=all
}

boop_cask() {
  if [[ "$#" = "0" ]]; then
    return 1
  fi

  if ! brew update; then
    return 1
  fi

  if ! brew cask install "$@"; then
    return 1
  fi

  brew cask cleanup
}

# Code signing helper for Homebrew binaries (notably GDB)

if [[ -s "${DCP_CONFIG_DIR}/brew_codesign.sha1" ]]; then
  brew_codesign() {
    if [[ ! "$(file -b "$1")" =~ ^Mach-O\ .+\ executable ]] &&
       ! [[ -d "$1" && -d "$1/Contents" ]]; then
      printf >&2 "Error: argument is not a Mach-O executable or bundle\n"
      return 1
    fi

    local executable_path

    if [[ ! -h "$1" ]]; then
      executable_path="$1"
    else
      executable_path="$(cd "$(dirname "$1")" && realpath -q "$(readlink -n "$1")")"
    fi

    /usr/bin/codesign --force \
                      --sign "$(cat "${DCP_CONFIG_DIR}/brew_codesign.sha1")" \
                      "${executable_path}"
  }
fi

#
# Quickly compute and copy a file's hash to the clipboard
#

copy_md5() {
  if [[ ! -f "$1" ]]; then
    printf >&2 "Argument is not a file\n"
    return 1
  fi
  
  local sum="$(md5 -q "$1")"
  printf "%s" "${sum}" | pbcopy
  printf "%s\n" "${sum}"
}

__copy_sha() {
  if [[ ! -f "$2" ]]; then
    printf >&2 "Argument is not a file\n"
    return 1
  fi

  local sum="$(shasum -p -a "$1" "$2" | cut -d ' ' -f 1)"
  printf "%s" "${sum}" | pbcopy
  printf "%s\n" "${sum}"
}

copy_sha1() { __copy_sha 1 "$1"; }
copy_sha256() { __copy_sha 256 "$1"; }
copy_sha384() { __copy_sha 384 "$1"; }

# Fix obnoxious bug with macOS zsh completion for /usr/bin/du if coreutils is
# installed via Homebrew.
if __is_zsh && [[ -x "/usr/local/opt/coreutils/bin/gdu" ]]; then
  du() { /usr/local/opt/coreutils/bin/gdu "$@"; }
fi

#
# System-level resets... these come in handy.
#

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
  printf >&2 "Flushing the DNS cache (enter your user password if prompted)...\n"

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
  launchctl setenv "$1" "$(__valueof "$1")"
}

# "action transformer" for protected services that can't be stopped traditionally
__lctl_protected_action() {
  case "$1" in
    stop)     printf "unstoppable";;
    restart)  printf "kickstart";;
    *)        printf "%s" "$1"
  esac
}

# launchctl wrapper for apsd (Apple Push Service: Messages.app, etc.)
apsctl() {
  "${DCP}/libexec/lctl.sh" apsctl \
                           system /System/Library/LaunchDaemons/com.apple.apsd.plist \
                           "$(__lctl_protected_action "$1")"
}

# launchctl wrapper for CoreAudio (because sometimes there be dragons)
coreaudioctl() {
  "${DCP}/libexec/lctl.sh" coreaudioctl \
                           system /System/Library/LaunchDaemons/com.apple.audio.coreaudiod.plist \
                           "$1"
}

# launchctl wrapper for bluetoothd
bluetoothctl() {
  "${DCP}/libexec/lctl.sh" bluetoothctl \
                           system /System/Library/LaunchDaemons/com.apple.bluetoothd.plist \
                           "$(__lctl_protected_action "$1")"
}

# launchctl wrapper for cfprefsd agent (clear file locks / empty the trash)
cfprefsctl() {
  "${DCP}/libexec/lctl.sh" cfprefsctl \
                           user /System/Library/LaunchAgents/com.apple.cfprefsd.xpc.agent.plist \
                           "$(__lctl_protected_action "$1")"
}

# gpgconf wrapper for gpg-agent, if installed via Homebrew

if [[ -h "/usr/local/opt/gnupg" ]]; then
  gpgagentctl() {
    if [[ "$1" = "stop" || "$1" = "restart" ]]; then
      /usr/local/bin/gpgconf --kill gpg-agent

      if [[ -n "$(ps -x | awk '$4 ~ /^gpg-agent/')" ]]; then
        killall gpg-agent
      fi
    fi

    if [[ "$1" != "stop" ]]; then
      /usr/local/bin/gpgconf --launch gpg-agent
    fi
  }
fi

# `brew services' wrappers for chunkwm, khd, and kwm if installed via Homebrew

if [[ -d "/usr/local/opt/chunkwm" ]]; then
  chunkwmctl() {
    if (($# == 0)); then
      return 1
    fi
    brew services "$@" crisidev/chunkwm/chunkwm
  }
fi
if [[ -d "/usr/local/opt/khd" ]]; then
  khdctl() {
    if (($# == 0)); then
      return 1
    fi
    brew services "$@" koekeishiya/formulae/khd
  }
fi
if [[ -d "/usr/local/opt/kwm" ]]; then
  kwmctl() {
    if (($# == 0)); then
      return 1
    fi
    brew services "$@" koekeishiya/formulae/kwm
  }
fi

# htop(1) should generally be run as root on macOS
if [[ -x "/usr/local/opt/htop/bin/htop" ]]; then
  htop() { sudo /usr/local/opt/htop/bin/htop "$@"; }
fi
