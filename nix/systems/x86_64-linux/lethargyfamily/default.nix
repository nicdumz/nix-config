{
  inputs,
  namespace,
  lib,
  ...
}:
{
  imports = [
    inputs.disko.nixosModules.disko
  ];

  disko.devices = lib.${namespace}.mkDiskLayout {
    swapsize = 16;
    # Take no chances and refer to the precise part.
    device = "/dev/disk/by-id/SAMSUNG_MZAL41T0HBLB-00BLL_S75WNE0W807108";
  };

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
    scaling = {
      defaultFontSize = 14;
      factor = 0.8;
    };
  };
  snowfallorg.users.giulia.create = true;
}
