{
  inputs,
  ezModules,
  ...
}:
{
  imports = [
    ezModules.persistence
    inputs.disko.nixosModules.disko
    ./configuration.nix
  ];

  disko.devices = (import ../../lib).mkDiskLayout "16G";

  networking.hostName = "lethargyfamily";

  # TODO: wifi?
  # networking.wireless.enable = true;
  # networking.wireless.userControlled.enable = true;
  # networking.wireless.userControlled.group = "network";

  # users.groups.network.members = [
  #   "giulia"
  #   "ndumazet"
  # ];

  nicdumz.graphical = true;
}
