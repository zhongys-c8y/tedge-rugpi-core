# Rugix thin-edge.io repository -- plus Alpine 

To make this repo also support Alpine OS, some recipes and layers need to be added. 

## Done 

- Created two layers for Alpine 
- Added Alpine in rugix-bakery.toml

## TODO

- ~~Systems.just -- add system for alpine~~
- justfile -- add alpine 
- Check recipes for Alpine. Start with 'defaults', followed by 'setup-network' and 'setup-pkcs11' 

### Defaults
Below are dependencies of current default recipe. Need to modify them for Alpine or skip if it is not necessary: 

    "core/persist-root-home", --> can be used for Alpine, needs verification 
    "rugix-extra/zsh", 

    "essentials", 
    "persist-network-manager", --> can be used for Alpine
    "set-wifi", --> skip, wifi not supported
    "ssh", --> can be used for Alpine, can be simplify 

    # containers
    "docker", --> no need, skip 

    # default cmdline options
    "boot-options", --> can be used for Alpine 

    # enable mdns (for statically compiled musl binaries)
    "systemd-resolved", --> not supported by Alpine, skip 

#### essentials
Dependencies of essentials. They are mostly for thin-edge: 

    "thin-edge.io",
    "persist-data",
    "persist-overlay",
    "tedge-bootstrap",
    "tedge-local-pki",
    "tedge-firmware-update",
    "mosquitto"

- thin-edge.io: its 01-install.sh can be compared to thin-edge's default install.sh to make it usable for alpine. It includes apt-get to install collectd, which can be removed first. It files and 00-packages looks fine. 

- persist-data: fine for Alpine

- persist-overlay: need to check 

- tedge-bootstrap: doesn't support alpine, would skip for the first version

- tedge-local-pki: doesn't support alpine, would skip for the first version

- tedge-firmware-update: doesn't support alpine, would skip for the first version 

- mosquitto: need to be modifed for Alpine


----------------
Original README
--------------
## Rugix thin-edge.io repository

**Additional recipes and layers for [Rugix](https://oss.silitics.com/rugix/).**

To make the recipes and layers available, include the following in your `rugix-bakery.toml`:

```toml
[repositories]
tedge-rugix-core = { git = "https://github.com/thin-edge/tedge-rugix-core.git", branch = "v0.8-rugix" }
```

We follow [Cargo's flavor of semantic versioning](https://doc.rust-lang.org/cargo/reference/resolver.html#semver-compatibility).
You can also use the most recent development version by omitting the `branch` property.
Please be aware that this may break your builds if we introduce backwards-incompatible changes.

## Development

Rugix supports running an image in a VM to facilitate local development (without a device).

To start a local virtual machine, run the following commands:

1. Start the vm (this will build the system image if necessary)

    ```sh
    just start-vm
    ```

2. Open a new console (leaving the previous one running), and connect to the VM

    ```sh
    just connect-vm
    ```

## Known Issues

* After a firmware update, the tedge-agent does not accept a new firmware operations until it is restarted, as it is waiting for the previous operation to be cleared (possibly due to use `tedge reconnect c8y`)

    ```log
    Mar 09 09:46:55 rpi4-d83add90fe56 tedge-agent[831]: 2025-03-09T09:46:55.514655111Z  INFO tedge_agent::operation_workflows::actor: Waiting successful firmware_update operation to be cleared
    ```

If something does not work, then please create a ticket.
