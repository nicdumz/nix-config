{
  namespace,
  lib,
  inputs,
  ...
}:
{
  imports = [
    inputs.disko.nixosModules.disko
    ./qemu-guest.nix
  ];

  disko.devices = lib.${namespace}.mkDiskLayout "16G";

  ${namespace} = {
    graphical = true;
    persistence.enable = true;
  };

  services.pcscd.enable = true;
}
