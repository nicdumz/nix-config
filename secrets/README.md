Encrypted secrets (using `sops` format via `sops-nix`) of keys that I want deployed on various
machines.

Run:

`sops updatekeys secrets/global.yaml && nix fmt`

To rewrap for new hosts.
