#!/bin/sh
set -e

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
fi

IS_ALPINE=0
if [ "$ID" = "alpine" ]; then
    IS_ALPINE=1
fi

# Persist tokens
install -D -m 644 "${RECIPE_DIR}/files/softhsm2-tokens.toml" -t /etc/rugix/state

# Add 'tedge' user to the 'softhsm' group
if [ "$IS_ALPINE" -eq 1 ]; then
    adduser tedge softhsm
else
    usermod -a -G softhsm tedge
fi

# Add helper scripts
install -m 0755 -d /usr/share/tedge-hsm/bin
install -D -m 0755 "${RECIPE_DIR}/files/init-softhsm.sh" -t /usr/share/tedge-hsm/bin/
