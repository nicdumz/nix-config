{
  pkgs,
  config,
  lib,
  inputs,
  ...
}:
{
  imports = [ inputs.catppuccin.nixosModules.catppuccin ];

  config = lib.mkIf config.nicdumz.graphical {
    catppuccin.enable = true;

    # TODO: modularize between hyprland and Gnome
    programs.hyprland.enable = true;
    programs.hyprlock.enable = true;
    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    services = {
      displayManager.sddm.enable = true;
      displayManager.sddm.wayland.enable = true;
      # udev.packages = [ pkgs.gnome-settings-daemon ];
    };

    environment = {
      systemPackages = with pkgs; [
        gedit
        # gnomeExtensions.appindicator
        # clipboard support
        wl-clipboard
      ];
    };
  };
}
