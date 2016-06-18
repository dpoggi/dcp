#
# Network admin things.
#

__net_open_things() {
  if ! hash netstat 2> /dev/null; then
    printf >&2 "netstat is not installed!\n"
    return 1
  fi

  printf "%s\n%s\n" "$1" \
    "$(sudo -H netstat --all --listening --program --numeric --wide | \
       awk "$2" | sort -g)" | column -t -o "    " | \
       sed -r -e 's/^([0-9]+)(\s+)(\w+):(\w+) (.*)$/\1\2\3: \4\5/'
}

# List open TCP/UDP ports.
net_open_ports() {
  sudo -H true
  printf "======== Open TCP/UDP Ports ========\n"
  __net_open_things "PID ProgramName Protocol BoundAddress" '{
    if ($1 ~ /(tcp)6?/ && $6 == "LISTEN")
    {
      sub("/", " ", $7)
      print $7 $8, $1, $4
    }
    else if ($1 ~ /(udp)6?/ && $6 != "ESTABLISHED")
    {
      sub("/", " ", $6)
      print $6, $1, $4
    }
  }'
}

# List open Unix sockets.
net_open_sockets() {
  sudo -H true
  printf "======== Open Unix Sockets ========\n"
  __net_open_things "PID ProgramName Path" '{
    if ($1 == "unix" && $7 == "LISTENING") {
      sub("/", " ", $9)
      print $9, $10
    }
  }'
}

# List all of it. List it all.
net_open_all() {
  net_open_ports
  printf "\n"
  net_open_sockets
}
