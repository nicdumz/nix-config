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

  disko.devices = lib.${namespace}.mkDiskLayout {
    swapsize = 0;
    device = "/dev/vda";
  };

  ${namespace} = {
    graphical = true;
    persistence.enable = true;
  };

  services.pcscd.enable = true;
  snowfallorg.users.ndumazet.create = false;
}
