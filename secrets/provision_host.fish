#!/usr/bin/env fish
# Adapt https://github.com/nix-community/nixos-anywhere/blob/main/docs/howtos/secrets.md
# for me.
if test (count $argv) -lt 1
    echo "Usage: provision_host <host> <optional other nixos-anywhere args>"
    echo "Reimage anew a host. Assumes host keys are already generated."
    exit
end

read -l -P 'Remember that this only works if the remote is *not* connected via wifi [enter to continue]' ignored

echo $argv | read -l host passthru
# Create a temporary directory
set temp $(mktemp -d)

# Function to cleanup temporary directory on exit
function cleanup --on-event fish_exit
    rm -rf "$temp"
end

# Create the directory where sshd expects to find the host keys
install -d -m755 "$temp/etc/ssh"

# Decrypt your private key from the password store and copy it to the temporary directory
sops decrypt --extract "[\"ssh_host_keys\"][\"$host\"]" ./secrets/deploy.yaml >"$temp/etc/ssh/ssh_host_ed25519_key"

# Set the correct permissions so sshd will accept the key
chmod 600 "$temp/etc/ssh/ssh_host_ed25519_key"

# Install NixOS to the host system with our secrets
#  1. No need for substitutions, local network is faster.
#  2. Do not reboot when done so I can inspect the state.
nix run github:nix-community/nixos-anywhere -- \
    --no-substitute-on-destination --no-reboot \
    --extra-files "$temp" --flake ".#$host" "$passthru" --target-host root@$host
