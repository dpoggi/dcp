if [[ "${SHLVL}" = "1" && -z "${SSH_TTY}" ]]; then
  if [[ -x /usr/bin/clear_console ]]; then
    /usr/bin/clear_console
  fi
fi

if [[ -s "${DCP}/localexit" ]]; then
  . "${DCP}/localexit"
fi
