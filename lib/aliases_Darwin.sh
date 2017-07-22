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
upgrading Vim from Homebrew. Run \`mm_off -a' now to restart this shell without
EOT

  printf >&2 "it/them (y/n)? "

  read -r

  if [[ "${REPLY}" = y* || "${REPLY}" = Y* ]]; then
    printf >&2 "\nRestarting the shell. Please run this command again.\n"
    mm_off -a
  fi
}

__boop_langs() {
  if [[ "${DCP_BOOP_LINK_LANGS}" != "true" ]]; then
    return
  fi

  brew "$1" node perl python ruby
}

boop() {
  __boop_check_pyenv

  __boop_langs link

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

  __boop_langs unlink

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
    if ! file -b "$1" | grep -q '^Mach-O.*executable'; then
      printf >&2 "Error: argument is not a Mach-O executable\n"
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

# Fix obnoxious bug with macOS zsh completion for /usr/bin/du if coreutils is
# installed via Homebrew.

if [[ -n "${ZSH_NAME}" && -x "/usr/local/opt/coreutils/bin/gdu" ]]; then
  alias du="gdu"

  if type compdef > /dev/null; then
     compdef gdu=du
  fi
fi


#
# System-level resets... these come in handy.
#

# Reset "Open With..." menus after connecting a drive with applications on it

reset_launch_services() {
  local framework="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework"

  "${framework}"/Support/lsregister -kill -r \
                                    -domain local \
                                    -domain system \
                                    -domain user
  killall Finder
}

# Flush DNS cache and reset mDNSResponder
reset_dns_cache() {
  printf >&2 "Flushing the DNS cache (enter your user password if prompted)...\n"

  if ! __is_file discoveryutil; then
    # Sane versions of macOS (mDNSResponder =~ government cheese)
    sudo -H dscacheutil -flushcache
    sudo -H killall -HUP mDNSResponder
  else
    # OS X 10.9 - 10.10.3 (RIP discoveryd)
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

# launchctl wrapper for apsd (Apple Push Service: Messages.app, etc.)
apsctl() {
  "${DCP}/libexec/lctl.sh" system "$1" "/System/Library/LaunchDaemons/com.apple.apsd.plist"
}

# launchctl wrapper for CoreAudio (because sometimes there be dragons)
coreaudioctl() {
  "${DCP}/libexec/lctl.sh" system "$1" "/System/Library/LaunchDaemons/com.apple.audio.coreaudiod.plist"
}

# gpgconf wrapper for gpg-agent, if installed by Homebrew
if [[ -h "/usr/local/opt/gnupg" ]]; then
  gpgagentctl() {
    if [[ "$1" = "stop" || "$1" = "restart" ]]; then
      /usr/local/bin/gpgconf --kill gpg-agent

      if [[ -n "$(ps -x | awk '$4 ~ /^gpg-agent/')" ]]; then
        killall gpg-agent
      fi
    fi

    /usr/local/bin/gpgconf --launch gpg-agent
  }
fi

# ctl scripts for kwm, if it and khd are installed via Homebrew
if [[ -d "/usr/local/opt/kwm" && -d "/usr/local/opt/khd" ]]; then
  __kwm_khd_stop() {
    brew services stop koekeishiya/formulae/khd
    brew services stop koekeishiya/formulae/kwm
  }

  __kwm_khd_start() {
    brew services start koekeishiya/formulae/kwm
    brew services start koekeishiya/formulae/khd
  }

  kwmctl() {
    case "$1" in
      start)
        __kwm_khd_start
        ;;
      stop)
        __kwm_khd_stop
        ;;
      restart)
        __kwm_khd_stop
        __kwm_khd_start
        ;;
      *)
        return 1
    esac
  }
fi

# ctl scripts for Emacs, if it's installed via Homebrew
if [[ -d "/usr/local/opt/emacs" ]]; then
  if [[ -s "${HOME}/.spacemacs" || -d "${HOME}/.spacemacs.d" ]]; then
    readonly DCP_EMACS_KILL_CMD="(spacemacs/kill-emacs)"
  else
    readonly DCP_EMACS_KILL_CMD="(kill-emacs)"
  fi

  __emacs_stop() {
    /usr/local/bin/emacsclient --eval "${DCP_EMACS_KILL_CMD}" 2> /dev/null
  }

  __emacs_kill() {
    killall Emacs
  }

  __emacs_start() {
    if ps -A | grep -Fq 'Emacs.app'; then
      return 1
    fi

    (cd "${HOME}" && /usr/local/bin/emacs --daemon > /dev/null 2>&1)
  }

  emacsctl() {
    case "$1" in
      start)
        __emacs_start
        ;;
      stop)
        __emacs_stop
        ;;
      kill)
        __emacs_kill
        ;;
      restart)
        __emacs_stop
        __emacs_start
        ;;
      kickstart)
        __emacs_kill
        __emacs_start
        ;;
      *)
        return 1
    esac
  }
fi


#
# Misc
#

if [[ -d "/usr/local/opt/htop-osx" ]]; then
  alias htop="sudo /usr/local/opt/htop-osx/bin/htop"
fi
