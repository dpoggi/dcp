if [[ -n "${ZSH_NAME}" ]]; then
  readonly DCP_SHELL="zsh"

  if [[ "$-" = *l* ]]; then
    readonly DCP_SHELL_INVOCATION="exec -l zsh -l"
  else
    readonly DCP_SHELL_INVOCATION="exec zsh"
  fi
else
  readonly DCP_SHELL="bash"

  if shopt -q login_shell 2> /dev/null; then
    readonly DCP_SHELL_INVOCATION="exec -l bash -l"
  else
    readonly DCP_SHELL_INVOCATION="exec bash"
  fi
fi
