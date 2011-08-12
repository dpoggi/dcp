#!/bin/sh

for FILE in $HOME/.dcp/dot/* $HOME/.vim/*rc; do
  if [ -s "$HOME/.$(basename $FILE)" ]; then
    echo "$HOME/.$(basename $FILE) already exists, not linking."
  else
    echo "Linking $HOME/.$(basename $FILE) => $FILE"
    ln -s "$FILE" "$HOME/.$(basename $FILE)"
  fi
done
