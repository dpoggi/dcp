# Load aliases
if [[ -e "${DCP}/lib/aliases.sh" ]]; then
  . "${DCP}/lib/aliases.sh"
fi

# Load OS-specific aliases, if appropriate
if [[ -e "${DCP}/lib/aliases_${DCP_OS}.sh" ]]; then
  . "${DCP}/lib/aliases_${DCP_OS}.sh"
fi

# Load local modifications
if [[ -s "${DCP}/localrc" ]]; then
  . "${DCP}/localrc"
fi
