#!/bin/sh
set -e

echo "----------------------------------------------------------------------------------"
echo "Executing $0"
echo "----------------------------------------------------------------------------------"
echo

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
fi

IS_ALPINE=0
if [ "$ID" = "alpine" ]; then
    IS_ALPINE=1
fi

# Rebuild the layer if the environment changes.
echo ".env" >> "${LAYER_REBUILD_IF_CHANGED}"
if [ -f "$RUGIX_PROJECT_DIR/.env" ]; then
    . "$RUGIX_PROJECT_DIR/.env"
fi

RECIPE_PARAM_CHANNEL="${RECIPE_PARAM_CHANNEL:-release}"

# Create user and group (Debian and Alpine compatible)
if [ "$IS_ALPINE" -eq 1 ]; then
    if ! getent group tedge >/dev/null; then
        addgroup -S -g 992 tedge
    fi
    if ! getent passwd tedge >/dev/null; then
        adduser -S -D -H -s "/sbin/nologin" -u 999 -G tedge tedge
    fi
else
    groupadd --system --gid 992 tedge || groupmod -g 992 tedge
    useradd --system --no-create-home --shell "/bin/false" --uid 999 --gid 992 tedge || usermod -u 999 tedge
fi

# Workaround for missing parameters in layer.toml
if [ -n "${TEDGE_INSTALL_CHANNEL:-}" ]; then
    echo "Using thin-edge.io install channel from env: TEDGE_INSTALL_CHANNEL=$TEDGE_INSTALL_CHANNEL" >&2
    RECIPE_PARAM_CHANNEL="$TEDGE_INSTALL_CHANNEL"
fi

# Install thin-edge.io
ARCH=$(uname -m)
INSTALL_OPTS=""
case "$ARCH" in
    *armv7*)
        echo "Using armv6 workaround" >&2
        INSTALL_OPTS="--arch armv6"
        ;;
esac

# Download file with retries (works in both Alpine & Debian)
download_file_with_retries() {
    max_attempts="$1"
    retries="$max_attempts"
    url="$2"
    tmp_file=$(mktemp)
    while ! wget -O "$tmp_file" "$url"; do
        retries=$((retries - 1))
        if [ "$retries" -lt 0 ]; then
            echo "ERROR: Failed to download after $max_attempts attempts. URL: $url" >&2
            return 1
        fi
        echo "WARNING: Retrying download ($((retries+1)) attempts remaining) in 5s..." >&2
        sleep 5
    done
    cat "$tmp_file"
    rm -f "$tmp_file"
}

# Install tedge from cloudsmith
download_file_with_retries 3 thin-edge.io/install.sh | sh -s -- --channel "$RECIPE_PARAM_CHANNEL" $INSTALL_OPTS

# Install required packages
if [ "$IS_ALPINE" -eq 1 ]; then
    apk update
    apk add --no-cache \
        mosquitto-clients \
        tedge-command-plugin \
        tedge-inventory-plugin \
        tedge-container-plugin-ng \
        collectd \
        networkmanager
else
    apt-get update
    apt-get install -y -o DPkg::Options::=--force-confnew --no-install-recommends \
        mosquitto-clients \
        tedge-command-plugin \
        tedge-collectd-setup \
        tedge-monit-setup \
        tedge-inventory-plugin
fi

# Enable NetworkManager
if [ "$IS_ALPINE" -eq 1 ]; then
    rc-update add NetworkManager default || true
else
    systemctl enable NetworkManager || true
fi

# Enable services (OpenRC for Alpine, systemctl for Debian)
if [ "$IS_ALPINE" -eq 1 ]; then
    rc-update add tedge-agent default
    rc-update add tedge-mapper-c8y default
    rc-update add tedge-mapper-collectd default
    rc-update add collectd default
else
    systemctl enable tedge-agent
    systemctl enable tedge-mapper-c8y
    systemctl enable tedge-mapper-collectd
    systemctl enable collectd
    systemctl disable c8y-firmware-plugin
fi

# Custom mosquitto configuration
if ! grep -q '^pid_file' /etc/mosquitto/mosquitto.conf; then
    install -D -m 644 "${RECIPE_DIR}/files/custom.conf" -t /etc/tedge/mosquitto-conf/
fi

# Use default tedge mosquitto settings before cloud connection
install -D -m 644 -g tedge -o tedge "${RECIPE_DIR}/files/tedge-mosquitto.conf" -t /etc/tedge/mosquitto-conf/

# Persist tedge configuration
install -D -m 644 "${RECIPE_DIR}/files/tedge-config.toml" -t /etc/rugix/state

# Add default plugin configurations
install -D -m 644 -g tedge -o tedge "${RECIPE_DIR}/files/tedge-configuration-plugin.toml" -t /etc/tedge/plugins/
install -D -m 644 -g tedge -o tedge "${RECIPE_DIR}/files/tedge-log-plugin.toml" -t /etc/tedge/plugins/

echo "Thin Edge.io installation completed successfully!"
