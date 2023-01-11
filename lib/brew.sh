#
# Homebrew
#

if [[ -x "/usr/local/bin/brew" ]]; then
  export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/sbin:${PATH}"
fi

if [[ -x "/opt/homebrew/bin/brew" ]]; then
  eval "$(
    /opt/homebrew/bin/brew shellenv | sed \
      -e 's|\${PATH+:\$PATH}";$|${PATH:+:${PATH}}";|' \
      -e 's|\${MANPATH+:\$MANPATH}:";$|${MANPATH:+:${MANPATH}}:";|' \
      -e 's|:\${INFOPATH:-}";$|${INFOPATH:+:${INFOPATH}}:";|'
  )"
fi
