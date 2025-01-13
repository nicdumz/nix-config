# This loads a vm in the current shell:
#   nix build vm.nix && ./result/bin/run-qemu-vm
# Log into it via ssh:
#   ssh -p 2222 root@localhost
let
  flake = builtins.getFlake (toString ./.);
in
flake.vm-noguiConfigurations.qemu
