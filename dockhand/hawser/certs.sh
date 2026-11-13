#!/bin/sh
set -eu

[ $# -eq 1 ] || { echo "usage: $0 <ip-or-hostname>" >&2; exit 1; }

mkdir -p certs

openssl req -x509 -nodes -days 3650 \
  -newkey rsa:4096 \
  -keyout certs/server.key \
  -out certs/server.crt \
  -subj "/CN=hawser" \
  -addext "subjectAltName=IP:$1,DNS:localhost"

chmod 600 certs/server.key
chmod 644 certs/server.crt
