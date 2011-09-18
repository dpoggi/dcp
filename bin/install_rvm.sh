#!/bin/sh

hash wget 2>&- && DCP_GET="wget --no-check-certificate --content-disposition -qO"
hash curl 2>&- && DCP_GET="curl -skL -o"
test "$DCP_GET" || { echo >&2 "Error! Couldn't find cURL or Wget!"; exit 1; }

OLD_WD=`pwd`
cd "$HOME"

$DCP_GET "rvm-installer.sh" "https://rvm.beginrescueend.com/install/rvm"
chmod +x "rvm-installer.sh"
rvm_bin_path="$HOME/.rvm/bin"
rvm_man_path="$HOME/.rvm/share/man"
bash "rvm-installer.sh" --version latest
rm -f "rvm-installer.sh"

cd "$OLD_WD"
