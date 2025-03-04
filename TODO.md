## Soon

- [x] create local VMs.
- [x] test deployment via (remote) `colmena` to local VM.
- [x] test nixos-anywhere install to a VM (reimage CUJ).
  https://github.com/nix-community/nixos-anywhere/blob/main/docs/quickstart.md
- [x] I want to have a nixos-anywhere workflow to create host ssh keys and provision new machines.
  Maybe https://github.com/nix-community/nixos-anywhere/blob/main/docs/howtos/secrets.md
- Secret management ([sops-nix?](https://github.com/Mic92/sops-nix)):
  - [ ] Have sops-nix support FIDO2 keys.
    - [ ] Remove my non FIDO key.
  - [x] Give sops-nix a try.
- [x] Once this works I want
  https://github.com/nix-community/nixos-anywhere/blob/main/docs/quickstart.md setup and tested.
- [x] Templates (actually, snippets) to create modules (home, and nixos).

## Later

- [x] xdg-open for kitty is broken at the moment.
- [ ] Fail tailscale deployment if > Apr 9th and ask to regenerate key.
- [x] Consider if I can fix the several gnubby touches per deployment problem.
- [ ] Consider encrypting and versioning some SSH keys.
- [ ] Cleanup /testing/ and integrate with the main flake

### Missing from dotfiles repo

- devdeck.
- obsidian + rclone configuration.

## Nice to have

- Why do I have to create empty home files ...
- New location for `secrets/provision_host.fish`?
- Maybe read pubkeys from some directory.
- Move stuff to features:
  - Go
  - ollama
  - role for a 'developer'
- I'd like to configure Librewolf extensions, e.g. have canvas blocker always allow strava,linkedin.
- I would love to have a "top" of vscode entry with nix things, how comes it seems to work on code
  on the laptop? :o
- Play with other greeters e.g. `regreet`.

## Could be useful

- https://github.com/nix-community/nixago could generate some files from nix language maybe
- consider https://github.com/maralorn/nix-output-monitor?tab=readme-ov-file
- https://nixery.dev/ for Docker?
- https://taskfile.dev/ seems interesting for common tasks
- https://github.com/mdlayher/homelab/blob/main/nixos/routnerr-3/networking.nix has a solid example
  of a nixos router config, + tailscale etc. Found via
  https://francis.begyn.be/blog/nixos-home-router

## Postponed

- can `Continue` config be versioned (right now it's in $HOME/.continue). _Postponed because I
  disabled it_.
