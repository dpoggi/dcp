# DCP
Dotfiles. Sensible defaults. Lots of them. Very opinionated.

## Installation
If you already have dotfiles, you'll need to get them out of the way for this to work as intended. You can run a script for deleting them (make backups first!) by doing this (THIS KILLS EVERYTHING! BE CAREFUL!):
```
curl -sL https://raw.githubusercontent.com/dpoggi/dcp/master/bin/dcp-remove_dotfiles | bash
```

Once you've got that handled, the installation script can be used as follows:
```
curl -sL https://raw.githubusercontent.com/dpoggi/dcp/master/bin/dcp-bootstrap | bash
```

If you have a .vim folder, I recommend deleting or moving it before you run the installation script. The "dotfile deletion" script doesn't touch that, but the installation script does try to clone my Vim configuration (https://github.com/dpoggi/dotvim).

## Attribution
A quick note: this repository started out as MY dotfiles - naturally, it predates its first Git commit. As such, there are snippets of code/shell script in here that I did not write (snipped from blogs, etc.). If you recognize a piece of code, please contact me so we can work things out to your satisfaction. Not trying to burn anyone here.

## Copyright
Copyright (C) 2011 Dan Poggi. MIT License, see LICENSE for details.
