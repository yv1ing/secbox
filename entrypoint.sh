#!/bin/sh
set -eu

mkdir -p /data
touch '/data/First Run'
rm -rf /data/Singleton*

# Chrome expects the D-Bus buses and the container has no init system to start
# them. Failures here only add log noise, so they are non-fatal.
mkdir -p /run/dbus
rm -f /run/dbus/pid /run/dbus/system_bus_socket
dbus-daemon --system --fork || echo "warning: system bus failed to start"
if addr=$(dbus-daemon --session --fork --print-address); then
  export DBUS_SESSION_BUS_ADDRESS="$addr"
else
  echo "warning: session bus failed to start"
fi

echo "sandbox entrypoint starting supervisord"
echo "noVNC desktop: http://<host>:8080/vnc.html?autoconnect=true&resize=remote"
echo "pi-web interface: http://<host>:30141"
exec supervisord -c /supervisord.conf
