if [[ -n "${ZSH_NAME}" ]]; then
  readonly DCP_SHELL="zsh"

  __is_bash() { false; }
  __is_zsh() { true; }

  if [[ "$-" = *l* ]]; then
    readonly DCP_SHELL_INVOCATION="exec -l zsh -l"
  else
    readonly DCP_SHELL_INVOCATION="exec zsh"
  fi
else
  readonly DCP_SHELL="bash"

  __is_bash() { true; }
  __is_zsh() { false; }

  if shopt -q login_shell 2> /dev/null; then
    readonly DCP_SHELL_INVOCATION="exec -l bash -l"
  else
    readonly DCP_SHELL_INVOCATION="exec bash"
  fi
fi
