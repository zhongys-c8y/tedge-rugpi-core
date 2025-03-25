#!/bin/bash
set -e

# Rebuild the layer if the environment changes.
echo ".env" >> "${LAYER_REBUILD_IF_CHANGED}"

if [ -f "$RUGIX_PROJECT_DIR/.env" ]; then
    # shellcheck disable=SC1091
    . "$RUGIX_PROJECT_DIR/.env"
fi

apk del bash util-linux wget dosfstools