{
  namespace,
  inputs,
  lib,
  ...
}:
{
  imports = [
    inputs.disko.nixosModules.disko
    ./configuration.nix
    ./windows-dual.nix
  ];

  disko.devices = lib.${namespace}.mkEncryptedDiskLayout {
    swapsize = 32;
    device = "/dev/disk/by-id/WD_BLACK_SN770_2TB_230502467307";
  };

  ${namespace} = {
    graphical = true;
    persistence.enable = true;
    tailscale.enable = true;
  };
  snowfallorg.users.giulia.create = true;
}
