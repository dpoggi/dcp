#!/bin/sh

for file in $HOME/.dcp/dot/* $HOME/.vim/*rc; do
  if [ -s "$HOME/.$(basename $file)" ]; then
    echo "$HOME/.$(basename $file) already exists, not linking."
  else
    echo "Linking $HOME/.$(basename $file) => $file"
    ln -s "$file" "$HOME/.$(basename $file)"
  fi
done
