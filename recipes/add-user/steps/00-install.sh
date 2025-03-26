#!/bin/sh
set -e

USERNAME="adminuser"
PASSWORD="adminuser"

# Create user
adduser "$USERNAME" -G "$USERNAME"

# echo "$USERNAME:$PASSWORD" | chpasswd

# adduser "$USERNAME" wheel

echo "User $USERNAME created successfully."
