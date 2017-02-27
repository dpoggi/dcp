if [[ -n "${ZSH_NAME}" ]]; then
  if [[ "$-" = *l* ]]; then
    readonly DCP_SHELL_INVOCATION="exec -l zsh -l"
  else
    readonly DCP_SHELL_INVOCATION="exec zsh"
  fi
else
  if shopt -q login_shell 2> /dev/null; then
    readonly DCP_SHELL_INVOCATION="exec -l bash -l"
  else
    readonly DCP_SHELL_INVOCATION="exec bash"
  fi
fi
