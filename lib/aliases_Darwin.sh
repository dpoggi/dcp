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
  if ! printf "%s" "${PATH}" | grep -Eq 'rbenv|pyenv|nvm'; then
    return
  fi

  if ! type disable_managers 2>&1 | grep -Fq ' function '; then
    return
  fi

  cat >&2 <<-EOT
rbenv, rvm, pyenv, and/or nvm found in PATH. This will break installing or
upgrading Vim from Homebrew. Run disable_managers function now to restart this
shell
EOT

  printf >&2 "without it/them (y/n)? "

  read -r

  if [[ "${REPLY}" = y* || "${REPLY}" = Y* ]]; then
    printf >&2 "\nRestarting the shell. Please run this command again.\n"
    disable_managers
  fi
}

__boop_vim_langs() {
  if [[ "${DCP_BOOP_VIM_LANGS}" != "true" ]]; then
    return
  fi

  if [[ "$1" != "link" && "$1" != "unlink" ]]; then
    return 1
  fi

  brew "$1" node perl python ruby
}

boop() {
  __boop_check_pyenv

  __boop_vim_langs link

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

  __boop_vim_langs unlink

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

  if hash discoveryutil 2> /dev/null; then
    # OS X 10.9 - 10.10.3 (RIP discoveryd)
    sudo -H discoveryutil mdnsflushcache
    sudo -H discoveryutil udnsflushcache
  else
    # Sane versions of macOS (mDNSResponder =~ government cheese)
    sudo -H dscacheutil -flushcache
    sudo -H killall -HUP mDNSResponder
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
  local var_name="$1"
  local var_value="$(eval "printf \"%s\" \"\${${var_name}}\"")"
  launchctl setenv "${var_name}" "${var_value}"
}

# launchctl wrapper for making things feel a little more... right.
__lctl() {
  if [[ "$#" -lt "3" || ! -s "$3" ]]; then
    return 1
  fi

  local action="$1"
  shift

  local target_domain
  if [[ "$1" = "user" || "$1" = "gui" ]]; then
    target_domain="$1/$(id -u)"
  else
    target_domain="$1"
  fi
  shift

  local plist="$(cd "$(dirname "$1")" && pwd -P)/$(basename "$1")"
  shift

  local service_target="${target_domain}/$(basename "${plist}" .plist)"

  local -a sudo_cmd
  if [[ "${plist}" = /Library* || "${plist}" = /System/Library* ]]; then
    sudo_cmd=(sudo -H)
  fi

  case "${action}" in
    start)
      ${sudo_cmd[*]} launchctl bootstrap "${target_domain}" "${plist}"
      ;;
    stop)
      ${sudo_cmd[*]} launchctl bootout "${service_target}"
      ;;
    restart)
      ${sudo_cmd[*]} launchctl kickstart -k "${service_target}"
      ;;
    enable)
      ${sudo_cmd[*]} launchctl enable "${service_target}"
      ;;
    disable)
      ${sudo_cmd[*]} launchctl disable "${service_target}"
      ;;
    *)
      return 1
      ;;
  esac
}

# launchctl wrapper for apsd (Apple Push Service: Messages.app, etc.)
apsctl() {
  __lctl "$1" system "/System/Library/LaunchDaemons/com.apple.apsd.plist"
}

# launchctl wrapper for CoreAudio (because sometimes there be dragons)
coreaudioctl() {
  __lctl "$1" system "/System/Library/LaunchDaemons/com.apple.audio.coreaudiod.plist"
}

# launchctl wrapper for gpg-agent, if installed by Homebrew
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

    (cd "${HOME}" && /usr/local/bin/emacs --daemon &> /dev/null)
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
