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

boop() {
  local -a formulae
  local purge="-s"
  local cask=""
  local cask_purge="--outdated"

  while [[ "$#" -gt "0" ]]; do
    case "$1" in
      --purge)
        purge="--prune=all"
        cask_purge=""
        ;;
      cask)
        cask="cask"
        ;;
      *)
        formulae+=("$1")
        ;;
    esac
    shift
  done

  brew update && \
  brew upgrade && \
  [[ -n "${formulae[@]}" ]] &&
    brew ${cask} install "${formulae[@]}" || true && \
  [[ -n "${cask}" ]] &&
    brew cask cleanup "${cask_purge}" || \
  brew cleanup --force "${purge}" || true
}


#
# System-level resets... these come in handy.
#

# Reset "Open With..." menus after connecting a drive with applications on it
reset_launch_services() {
  /System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister -kill -r -domain local -domain system -domain user
  killall Finder
}

# Flush DNS cache and reset mDNSResponder
reset_dns_cache() {
  printf >&2 "Flushing the DNS cache (enter your user password if prompted)...\n"

  if hash discoveryutil 2> /dev/null; then
    # OS X 10.9 - 10.10.3
    sudo discoveryutil mdnsflushcache
    sudo discoveryutil udnsflushcache
  else
    # Sane versions of OS X
    sudo dscacheutil -flushcache
    sudo killall -HUP mDNSResponder
  fi
}

# Clear Quick Look's file locks (so you can empty the trash)
reset_quick_look() {
  qlmanage -r
}


#
# Oracle Jabba or: How I Learned to Stop Worrying...
# and Begrudgingly Accept the State of Multiple Java Installs on OS X
# Yes, I've seen jenv. No, I don't think I like it.
#

use_jdk() {
  [[ "$#" -gt "0" ]] || return 1

  # Finds the newest JDK available based on first two args.
  local pattern
  if [[ -n "$2" ]]; then
    pattern="jdk1.${1}.0_${2}.jdk"
  else
    pattern="jdk1.${1}.0_*.jdk"
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
  sudo ln -snfv "${jdk_dir}/Contents/Home" "/Library/Java/Home"
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
  local -a sudo_cmd
  if [[ "$1" = "sudo" ]]; then
    sudo_cmd=(sudo -H)
    shift
  fi

  case "$1" in
    start)
      shift
      ${sudo_cmd[*]} launchctl load -F "$@"
      ;;
    stop)
      shift
      ${sudo_cmd[*]} launchctl unload -F "$@"
      ;;
    restart)
      shift
      ${sudo_cmd[*]} launchctl unload -F "$@"
      ${sudo_cmd[*]} launchctl load -F "$@"
      ;;
    "")
      return 1
      ;;
    *)
      ${sudo_cmd[*]} launchctl "$@"
      ;;
  esac
}

# launchctl wrapper for apsd (Apple Push Service: Messages.app, etc.)
apsctl() {
  __lctl sudo \
         "$1" \
         "/System/Library/LaunchDaemons/com.apple.apsd.plist"
}

# launchctl wrapper for CoreAudio (because sometimes there be dragons)
coreaudioctl() {
  __lctl sudo \
         "$1" \
         "/System/Library/LaunchDaemons/com.apple.audio.coreaudiod.plist"
}

# launchctl wrapper for gpg-agent, if the plist is installed
if [[ -s "${HOME}/Library/LaunchAgents/com.danpoggi.gpg-agent.plist" ]]; then
  gpgagentctl() {
    if [[ "$1" = "stop" || "$1" = "restart" ]]; then
      killall gpg-agent
    fi
    __lctl "$1" \
           -S Aqua \
           "${HOME}/Library/LaunchAgents/com.danpoggi.gpg-agent.plist"
  }
fi

# ctl script for Emacs, if it's installed via Homebrew
if [[ -d "/usr/local/opt/emacs" ]]; then
  if [[ -s "${HOME}/.spacemacs" || -d "${HOME}/.spacemacs.d" ]]; then
    DCP_EMACS_KILL_CMD="(spacemacs/kill-emacs)"
  else
    DCP_EMACS_KILL_CMD="(kill-emacs)"
  fi

  __emacs_stop() {
    /usr/local/opt/emacs/bin/emacsclient \
      --eval "${DCP_EMACS_KILL_CMD}" \
      2> /dev/null
  }

  __emacs_kill() {
    killall Emacs
  }

  __emacs_start() {
    if ps -A | grep -q 'Emacs\.app'; then
      return 1
    fi
    (cd "${HOME}" && /usr/local/opt/emacs/bin/emacs --daemon &> /dev/null)
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
