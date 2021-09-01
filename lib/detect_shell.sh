DCP_SHELL_EXEC_CMD=(exec)

if [[ -n "${ZSH_NAME}" ]]; then
  readonly DCP_SHELL="zsh"
  readonly DCP_SHELL_RET_SIGNAL="EXIT"

  __is_bash() { false; }
  __is_zsh() { true; }

  if [[ "$-" = *l* ]]; then
    DCP_SHELL_EXEC_CMD+=(-l zsh -l)
  else
    DCP_SHELL_EXEC_CMD+=(zsh)
  fi
else
  readonly DCP_SHELL="bash"
  readonly DCP_SHELL_RET_SIGNAL="RETURN"

  __is_bash() { true; }
  __is_zsh() { false; }

  if [[ "$0" = -* ]]; then
    DCP_SHELL_EXEC_CMD+=(-l)
  fi

  DCP_SHELL_EXEC_CMD+=(bash)

  if shopt -q login_shell 2>/dev/null; then
    DCP_SHELL_EXEC_CMD+=(-l)
  fi
fi

readonly DCP_SHELL_EXEC_CMD
