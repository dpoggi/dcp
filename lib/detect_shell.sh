DCP_SHELL_INVOCATION=(exec)

if [[ -n "${ZSH_NAME}" ]]; then
  readonly DCP_SHELL="zsh"

  __is_bash() { false; }
  __is_zsh() { true; }

  if [[ "$-" = *l* ]]; then
    DCP_SHELL_INVOCATION+=(-l zsh -l)
  else
    DCP_SHELL_INVOCATION+=(zsh)
  fi
else
  readonly DCP_SHELL="bash"

  __is_bash() { true; }
  __is_zsh() { false; }

  if [[ "$0" = -* ]]; then
    DCP_SHELL_INVOCATION+=(-l)
  fi

  DCP_SHELL_INVOCATION+=(bash)

  if shopt -q login_shell 2>/dev/null; then
    DCP_SHELL_INVOCATION+=(-l)
  fi
fi

readonly DCP_SHELL_INVOCATION
