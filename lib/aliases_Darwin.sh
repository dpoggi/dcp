#
# Xcode aliases
#

# Open Xcode for current folder (prefers workspace to project)
xc() {
  open -a "/Applications/Xcode.app" .
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

  if hash discoveryutil 2>/dev/null; then
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

  # Finds the newest Java _ (first argument) JDK available
  local pattern
  [[ "$1" -ge "9" ]] && pattern="jdk${1}*" || pattern="jdk1\.${1}*"

  local jdk_dir="$(command find "/Library/Java/JavaVirtualMachines" \
    -maxdepth 1 -name "${pattern}" -print | tail -n 1)"
  [[ -d "${jdk_dir}" ]] || { printf >&2 "Java $1 not found.\n"; return 1; }

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
  local var="$1"
  local val="$(eval "printf \"\${${var}}\"")"
  launchctl setenv "${var}" "${val}"
}

# launchctl wrapper for making things feel a little more... right.
__lctl() {
  local -a sudo_cmd
  if [[ "$1" = "sudo" ]]; then
    sudo_cmd+=(sudo -H)
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
  __lctl sudo "$1" "/System/Library/LaunchDaemons/com.apple.apsd.plist"
}

# launchctl wrapper for CoreAudio (because sometimes there be dragons)
coreaudioctl() {
  __lctl sudo "$1" "/System/Library/LaunchDaemons/com.apple.audio.coreaudiod.plist"
}

# launchctl wrapper for gpg-agent, if the plist is installed
if [[ -e "${HOME}/Library/LaunchAgents/homebrew.mxcl.gpg.agent.plist" ]]; then
  gpgagentctl() {
    [[ "$1" = "stop" || "$1" = "restart" ]] && killall gpg-agent
    __lctl "$1" -S Aqua "${HOME}/Library/LaunchAgents/homebrew.mxcl.gpg.agent.plist"
  }
fi


#
# Misc
#

# Holy crap an Emacs alias.
if [[ -e "/Applications/Emacs.app" ]]; then
  alias guemacs="open -a /Applications/Emacs.app"
fi

# Kill running Emacs
kill_emacs() {
  __kill_emacs

  local plist="${HOME}/Library/LaunchAgents/homebrew.mxcl.emacs-mac.plist"
  if [[ -e "${plist}" ]]; then
    launchctl unload -F "${plist}"
  fi
}