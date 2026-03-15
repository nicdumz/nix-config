{
  pkgs,
  config,
  lib,
  inputs,
  namespace,
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
      # Allows remembering the last logged in user.
      accounts-daemon.enable = true;
      # udev.packages = [ pkgs.gnome-settings-daemon ];
    };

    ${namespace} = {
      # needs persistence
      persistence.directories = [
        {
          directory = config.users.users.sddm.home;
          user = config.users.users.sddm.name;
          inherit (config.users.users.sddm) group;
        }
      ];
    };
    # TODO: upstream
    systemd.services.display-manager.unitConfig.RequiresMountsFor = [
      config.users.users.sddm.home
    ];

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
