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

  networking.networkmanager.enable = true;
  # Would be for homemanager
  # services.network-manager-applet.enable = true;

  ${namespace} = {
    graphical = true;
    persistence.enable = true;
    tailscale.enable = true;
    scaling = {
      defaultFontSize = 14;
      factor = 0.8;
    };
  };
}
