# DCP

Dotfiles. Big, maximalist, and scary. Working on trimming this stuff down.

## Installation

The installation script can be used as follows:

```bash
curl -fSL https://dcp.danpoggi.com | bash
```

This URL is a temporary redirect to
`https://raw.githubusercontent.com/dpoggi/dcp/master/bin/dcp-bootstrap`.

If you have a .vim folder, I recommend deleting or moving it before you run the
installation script. The installer includes my
[Vim configuration](https://github.com/dpoggi/dotvim).

Any dotfiles that are "in the way" when the script attempts to symlink them
into `~/.dcp` will be ignored and called out — it's completely up to you
whether to leave them in the way or clear them out in favor of those provided.
To link remaining dotfiles after deleting or moving them out of the way, run
`~/.dcp/bin/dcp-install-links`.

## Version Managers

rbenv or RVM, pyenv (with or without pyenv-virtualenv), NVM, and rustup are
supported out of the box. In practice, this means if they or their installers
modify any "normal" dotfiles (`.bashrc`, etc.) it would be wise to:

```bash
(cd ~/.dcp && git checkout .)
```

This built-in support comes with shell functions to control the loading of
version managers. Be warned that all of these will re-exec your shell:

```bash
disable_managers # Disable all
enable_managers  # Enable all

enable_rvm
enable_rbenv
enable_pyenv
enable_nvm
enable_rustup
```

Shell re-exec behavior is somewhat smart-ish. For example, on a typical macOS
setup with iTerm2 or Terminal.app and zsh, it will `exec -l zsh -l`. Running
zsh in a graphical terminal on Linux, it will most likely just `exec zsh`.

## Customization

One of the primary goals of this project has always been maintaining at least
shaky portability over a wide variety of platforms, using both `bash` and
`zsh`.

As such, this repository wants to take over all your "normal" dotfiles.
Customizations are then made in specific files which will be loaded by both
shells.

`~/.dcp/localenv` is primarily for setting environment variables and will be
loaded quite early. `~/.dcp/localrc` is loaded slightly later and should be
used for shell functions or any custom integrations. Both of these files are
gitignored.

## Portability Notes

In general: macOS and Linux will be the smoothest experience. BSDs may or may
not work depending which ports/packages have been installed, and Solaris
distributions can go either way depending how you/they have `$PATH` set up.

## Attribution

The contents of this repository predate the initial Git commit. There may be
some snippets of shell script that I did not write (snipped from blogs,
StackOverflow, etc.). Attribution has been done on a best-effort basis. If you
recognize something here as your own, please do not hesitate to contact me so
we can work things out to your satisfaction.

## Copyright

Copyright (C) 2011 Dan Poggi. MIT License, see LICENSE for details.
