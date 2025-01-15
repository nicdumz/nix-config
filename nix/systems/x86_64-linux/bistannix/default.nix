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

  disko.devices = lib.${namespace}.mkEncryptedDiskLayout "32";

  ${namespace} = {
    graphical = true;
    persistence.enable = true;
  };
  snowfallorg.users.giulia.create = true;
}
