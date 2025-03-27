#!/bin/sh
set -eu

adduser -D -s /bin/sh dev
echo "dev:dev" | chpasswd
echo root:root | chpasswd

adduser "dev" wheel

echo "Created user"
