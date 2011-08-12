#!/bin/sh

OLD_WD=`pwd`
cd "$HOME"

curl -skL -o rvm-installer.sh https://rvm.beginrescueend.com/install/rvm
chmod +x rvm-installer.sh
rvm_bin_path="$HOME/.rvm/bin"
rvm_man_path="$HOME/.rvm/share/man"
./rvm-installer.sh --version latest
rm -f rvm-installer.sh

cd "$OLD_WD"
