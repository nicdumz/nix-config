# Nix configurations

This is a replacement of my previous [dotfiles](https://github.com/nicdumz/dotfiles) setup, except
that on top of user configuration intent this repo also encodes machine configuration intent.

- Nix + Home Manager manage the "dotfiles" home user configuration intent.
- Where I can control the OS, I run NixOS.

## Structure

I follow exactly the structure from [snowfall-lib](https://snowfall.org/guides/lib/quickstart/) and
recommend a read to understand their philosophy.

```
├── nix/                    snowfall-lib structure
│── secrets/                agenix encrypted secrets
├── .envrc                  direnv directive
├── README.md               Github Repo landing page
├── flake.nix               Core flake
├── flake.lock              Lockfile
└── LICENSE                 Project License
```

## Features

- Secret management: integration with `agenix`/`agenix-rekey` lets me check-in encrypted secrets. My FIDO2 keys allow for decryption/rewrapping for a new host's pubkey. After deployment to a new host, the host can decrypt its secrets, exposing them via `/run/...` to the correct application.
- Multi-machine, multi-user by design.
- `disko` handles partition layout for new installs.
- Development on this repo:
  - `direnv` integration: if you `cd` into the repo you should get a useable development environment.
  - `nix fmt` in this repo just does the right thing.

## Usage examples

Everyday usage:

```sh
colmena --experimental-flake-eval build  # builds all things
nixos-rebuild build --flake .#bistannix # build for one host
nixos-rebuild switch --flake .#bistannix --use-remote-sudo # deploy for current machine
```

Building an iso for a liveusb purpose (containing this repo in `$HOME/nixos-sources`):

```sh
nix build .#nixosConfigurations.liveusb.config.system.build.isoImage
```

Deploying a new machine (with disk partitioning):

```sh
sudo nix run 'github:nix-community/disko/latest#disko-install' -- --write-efi-boot-entries --flake '.#bistannix' --disk main /dev/sda
```
