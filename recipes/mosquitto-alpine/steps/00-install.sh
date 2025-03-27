#!/bin/sh -e
# Install Mosquitto MQTT broker on Alpine Linux

# Used fixed uid/gid to avoid permission issues across A/B updates
if ! getent group mosquitto >/dev/null; then
    addgroup -S -g 960 mosquitto
else
    sed -i "/^mosquitto:/s/:[0-9]*:/:960:/" /etc/group
fi

if ! getent passwd mosquitto >/dev/null; then
    adduser -S -D -H -s "/sbin/nologin" -u 961 -G mosquitto mosquitto
else
    sed -i "/^mosquitto:/s/:[0-9]*:960:/:961:960:/" /etc/passwd
fi

ARCH=$(uname -m)

case "$ARCH" in
    armv7l|armhf)
        echo "Skipping Mosquitto installation as it is only supported on arm64 images" >&2
        exit 0
        ;;
esac

# Update packages and install Mosquitto
apk update
apk add --no-cache mosquitto mosquitto-clients

# Enable Mosquitto to start on boot (Alpine uses OpenRC)
rc-update add mosquitto default

# Ensure Mosquitto does not start before the network is ready
# mkdir -p /etc/init.d/mosquitto
cat <<EOT > /etc/init.d/mosquitto
#!/sbin/openrc-run
name="Mosquitto MQTT broker"
command="/usr/sbin/mosquitto"
command_args="-c /etc/mosquitto/mosquitto.conf"
command_args_background="-d"
description="Lightweight MQTT broker"

depend() {
    need net
}

start_pre() {
    mkdir -p /var/lib/mosquitto
    chown -R mosquitto:mosquitto /var/lib/mosquitto
    checkpath -d -m 0755 -o mosquitto:mosquitto /var/run/mosquitto

}
EOT
chmod +x /etc/init.d/mosquitto

# Restart Mosquitto only if it's already running
if rc-service mosquitto status >/dev/null 2>&1; then
    rc-service mosquitto restart
fi

# Display installed version
MOSQUITTO_VERSION=$(mosquitto -h 2>&1 | grep -oE 'mosquitto version [0-9.]+' | awk '{print $3}')
echo "Mosquitto version: $MOSQUITTO_VERSION"
