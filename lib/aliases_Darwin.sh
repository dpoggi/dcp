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
  if ! printf "%s" "${PATH}" | grep -Fq 'pyenv'; then
    return
  fi
  if ! type no_managers 2>&1 | grep -Fq 'function'; then
    return
  fi

  printf >&2 "pyenv found in \$PATH. This will break installing/upgrading Vim from Homebrew.\n"
  printf >&2 "Run no_managers function now to restart this shell without it (y/n)? "
  read -r

  if [[ "${REPLY}" = y* || "${REPLY}" = Y* ]]; then
    printf >&2 "\nRestarting the shell. Please run this command again.\n"
    no_managers
  fi
}

boop() {
  if [[ "$1" = "cask" ]]; then
    local cask="true"
    shift
  fi

  local -a formulae
  while [[ "$#" -gt "0" ]]; do
    formulae+=( "$1" )
    shift
  done

  __boop_check_pyenv

  brew update
  if [[ "$?" != "0" ]]; then
    return "$?"
  fi

  brew upgrade
  if [[ "$?" != "0" ]]; then
    return "$?"
  fi

  if [[ -n "${formulae[*]}" ]]; then
    if [[ "${cask}" = "true" ]]; then
      brew cask install "${formulae[@]}"
    else
      brew install "${formulae[@]}"
    fi
  fi

  if [[ "${cask}" = "true" ]]; then
    brew cask cleanup
  else
    brew cleanup --prune=all
  fi
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
# Oracle Jabba or: How I Learned to Stop Worrying...
# and Begrudgingly Accept the State of Multiple Java Installs on macOS
# Yes, I've seen jenv. No, I don't think I like it.
#

use_jdk() {
  if [[ "$#" -lt "1" ]]; then
    return 1
  fi

  local jdk_word

  if [[ "$1" = "zulu" ]]; then
    jdk_word="zulu"
    shift
  else
    jdk_word="jdk"
  fi

  # Finds the newest JDK available based on first two args.

  local pattern

  if [[ -n "$2" ]]; then
    pattern="${jdk_word}1.${1}.0_${2}.jdk"
  else
    pattern="${jdk_word}1.${1}.0_*.jdk"
  fi

  local jdk_dir="$(find "/Library/Java/JavaVirtualMachines" \
                        -mindepth 1 \
                        -maxdepth 1 \
                        -name "${pattern}" \
                        -print \
                     | sort -n -t_ -k2,2 \
                     | tail -n 1)"
  if [[ ! -d "${jdk_dir}" ]]; then
    local update
    if [[ -n "$2" ]]; then
      update="u$2"
    fi
    printf >&2 "JDK $1${update} not found.\n"
    return 1
  fi

  printf >&2 "Using $(basename "${jdk_dir}") (enter your user password if prompted)...\n"
  sudo -H ln -snfv "${jdk_dir}/Contents/Home" "/Library/Java/Home"
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

# launchctl wrapper for gpg-agent, if the plist is installed
if [[ -s "${HOME}/Library/LaunchAgents/com.danpoggi.gpg-agent.plist" ]]; then
  gpgagentctl() {
    if [[ "$1" = "stop" || "$1" = "restart" ]]; then
      killall gpg-agent 2> /dev/null
    fi
    __lctl "$1" gui "${HOME}/Library/LaunchAgents/com.danpoggi.gpg-agent.plist"
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
    DCP_EMACS_KILL_CMD="(spacemacs/kill-emacs)"
  else
    DCP_EMACS_KILL_CMD="(kill-emacs)"
  fi

  __emacs_stop() {
    /usr/local/bin/emacsclient \
      --eval "${DCP_EMACS_KILL_CMD}" \
      2> /dev/null
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
