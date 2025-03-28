#!/bin/sh

if [ -e /bin/bash ] || [ -L /bin/bash ]; then
    echo "Remove existing /bin/bash link"
    rm -f /bin/bash
fi

echo "Create /bin/bash -> /bin/zsh link"
ln -s /bin/zsh /bin/bash

if [ "$(readlink -f /bin/bash)" = "/bin/zsh" ]; then
    echo "Link created"
else
    echo "Failed to create /bin/bash -> /bin/zsh link"
    exit 1
fi
