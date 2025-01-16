{
  inputs,
  namespace,
  lib,
  ...
}:
{
  imports = [
    inputs.disko.nixosModules.disko
    ./configuration.nix
  ];

  disko.devices = lib.${namespace}.mkDiskLayout "16G";

  # TODO: wifi?
  # networking.wireless.enable = true;
  # networking.wireless.userControlled.enable = true;
  # networking.wireless.userControlled.group = "network";

  # users.groups.network.members = [
  #   "giulia"
  #   "ndumazet"
  # ];

  ${namespace} = {
    graphical = true;
    persistence.enable = true;
    tailscale.enable = true;
  };
  snowfallorg.users.giulia.create = true;
}
