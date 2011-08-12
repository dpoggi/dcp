#!/bin/sh

# Save the whales! I mean working directory!
wd=`pwd`
cd "$HOME"

# Freak out and quit if we don't have Git and/or cURL.
hash git 2>&- || { echo >&2 "We need Git first, cap'n!"; cd "$wd"; exit 1; }
hash curl 2>&- || { echo >&2 "Also cURL. cURL would be good."; cd "$wd"; exit 1; }

# Clone oh-my-zsh regardless, not a single fuck is given this day.
git clone git://github.com/robbyrussell/oh-my-zsh.git .oh-my-zsh

# If it's me, I want to be able to change my dotfiles,
# otherwise clone the public repos.
if [ "$ITS_ME" ]; then
  git clone git@github.com:dpoggi/dcp.git .dcp
  git clone git@github.com:dpoggi/dotvim.git .vim
else
  git clone git://github.com/dpoggi/dcp.git .dcp
  git clone git://github.com/dpoggi/dotvim.git .vim
fi

# Install RVM and pythonbrew:
curl -skL -o rvm-installer https://rvm.beginrescueend.com/install/rvm
chmod +x rvm-installer
rvm_bin_path="$HOME/.rvm/bin"
rvm_man_path="$HOME/.rvm/share/man"
./rvm-installer --version latest
rm -f rvm-installer .rvmrc

curl -skL http://xrl.us/pythonbrewinstall | bash

# Get Vim rockin'
cd "$HOME/.vim"
git submodule update --init
cd "$HOME"

# Install the symlinks
$HOME/.dcp/bin/install_dcp.sh

# Get back to where we were
cd "$wd"

# Report.
echo
echo "Bro-tips: restart your shell, don't forget to compile Command-T."
