#!/bin/sh -e

# Update package list
apk update

# Install required packages
apk add --no-cache \
    cgroup-tools \
    podman \
    podman-compose \
    fuse-overlayfs\

sed -i 's/#mount_program/mount_program/' /etc/containers/storage.conf
sed -i 's/.*rc_cgroup_mode=.*/rc_cgroup_mode="unified"/g' /etc/rc.conf

## Cannot be used when building image 
# modprobe tun
# echo tun >>/etc/modules
# echo <USER>:100000:65536 >/etc/subuid
# echo root:100000:65536 >/etc/subuid
# echo root:100000:65536 >/etc/subgid

rc-update add podman

## Error: Service is already started
# service podman restart

# Copy podman persist file
install -D -m 644 "${RECIPE_DIR}/files/podman.toml" -t /etc/rugix/state

## Crashed mosquitto 
# Add mosquitto listener which allows other containers access to the thin-edge.io MQTT broker
#install -D -m 0644 "${RECIPE_DIR}/files/tedge-networkcontainer.conf" -t /etc/tedge/mosquitto-conf/

# Add sudoers rules
install -D -m 0644 "${RECIPE_DIR}/files/suoders.tedge-container-plugin" -t /etc/sudoers.d/tedge-container-plugin