{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:
{
  imports = [ inputs.stylix.nixosModules.stylix ];

  config = lib.mkIf config.nicdumz.graphical {
    stylix.homeManagerIntegration.autoImport = false;
    stylix.homeManagerIntegration.followSystem = false;

    # TODO: modularize between hyprland and Gnome
    programs.hyprland.enable = true;
    programs.hyprlock.enable = true;
    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    services = {
      displayManager.gdm.enable = true;
      udev.packages = [ pkgs.gnome-settings-daemon ];
    };

    environment = {
      systemPackages = with pkgs; [
        gedit
        gnomeExtensions.appindicator
        # clipboard support
        wl-clipboard
      ];
    };
  };
}
