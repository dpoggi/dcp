# Load aliases
. "${DCP}/lib/aliases.sh"

# Load OS-specific aliases, if available
if [[ -s "${DCP}/lib/aliases_${DCP_OS}.sh" ]]; then
  . "${DCP}/lib/aliases_${DCP_OS}.sh"
fi

# Load local modifications, if available
if [[ -s "${DCP}/localrc" ]]; then
  . "${DCP}/localrc"
fi
