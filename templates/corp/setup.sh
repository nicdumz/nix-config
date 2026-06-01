#!/bin/bash
sudo apt install -y nix

if [ ! -d "$HOME/code/nix-config" ]; then
    mkdir -p "$HOME/code"
    jj git clone git@github.com:nicdumz/nix-config "$HOME/code/nix-config"
fi

if ! getent group nix-users | grep -qw "$USER"; then
    sudo usermod -a -G nix-users "$USER"
fi
if ! grep -q "flakes" /etc/nix/nix.conf; then
    conf="$(printf 'experimental-features = nix-command flakes\ntrusted-users = root ndumazet')"
    sudo tee -a /etc/nix/nix.conf <<< $conf
    sudo systemctl restart nix-daemon.service

fi
# Run in newgrp to avoid having to reboot.
newgrp nix-users <<EON
nix run github:nix-community/home-manager/release-25.11 -- switch --flake ~/.config/home-manager -b backup
EON
