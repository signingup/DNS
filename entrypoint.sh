#!/bin/bash

FILE="/etc/dns/start.sh"

if [ -f "$FILE" ]; then
  cp "$FILE" /usr/bin/start
  chmod +x /usr/bin/start && /usr/bin/start
fi
