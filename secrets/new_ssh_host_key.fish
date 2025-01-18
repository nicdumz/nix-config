#!/usr/bin/env fish
if test (count $argv) -ne 1
    echo "Usage: new_ssh_host_key <host>"
    echo "Generates a new host key for host, puts it in deploy.yaml and prints the age public key"
    exit
end
set host $argv[1]
# Create a temporary directory
set temp $(mktemp -d)

# Function to cleanup temporary directory on exit
function cleanup --on-event fish_exit
    rm -rf "$temp"
end

set keyfile $temp/sshkey
ssh-keygen -t ed25519 -q -N "" -C "ssh host key for $host" -f $keyfile
sops set ./secrets/deploy.yaml "[\"ssh_host_keys\"][\"$host\"]" "$(jq -Rsa . < $keyfile)"
nix fmt ./secrets/deploy.yaml &>/dev/null
# Print public key on stdout
ssh-to-age -i "$keyfile.pub"
