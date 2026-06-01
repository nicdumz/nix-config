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

  config = lib.mkIf config.nicdumz.device.isGraphical {
    catppuccin.enable = true;

    # TODO: modularize between hyprland and Gnome
    programs = {
      hyprland.enable = true;
      # TODO: 26.05 do I need the following?
      # hyprland.withUWSM = true;
      hyprlock.enable = true;
    };
    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    services = {
      displayManager.sddm.enable = true;
      displayManager.sddm.wayland.enable = true;
      # Allows remembering the last logged in user.
      accounts-daemon.enable = true;
      # udev.packages = [ pkgs.gnome-settings-daemon ];
      gnome.gnome-keyring.enable = true;

      # TODO 26.05: remove this override. I only keep it here to avoid the switch inhibitor which
      # comes with it. By itself it doesn't sound broken, just needs a clean switch later.
      dbus.implementation = "dbus";
    };

    security.pam.services = {
      sddm.enableGnomeKeyring = true;
      hyprlock.enableGnomeKeyring = true;
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

    environment = {
      systemPackages = with pkgs; [
        gedit
        # gnomeExtensions.appindicator
        # clipboard support
        wl-clipboard
        hyprshot
      ];
      pathsToLink = [
        "/share/xdg-desktop-portal"
        "/share/applications"
      ];
    };
  };
}
