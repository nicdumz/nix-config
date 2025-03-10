{
  pkgs,
  config,
  lib,
  ...
}:
{
  config = lib.mkIf config.nicdumz.graphical {
    services = {
      # NOTE: this actually is using wayland.
      # NOTE: Remember to add gammastep, redshift or similar if moving away from gnome.
      xserver = {
        enable = true;
        displayManager.gdm.enable = true;
        desktopManager.gnome.enable = true;
      };
      udev.packages = [ pkgs.gnome-settings-daemon ];
    };

    environment = {
      gnome.excludePackages = with pkgs; [
        atomix # puzzle game
        cheese # webcam tool
        epiphany # web browser
        evince # document viewer
        geary # email reader
        gnome-calendar
        gnome-characters
        gnome-console
        gnome-contacts
        gnome-maps
        gnome-music
        gnome-photos
        gnome-software
        gnome-terminal
        gnome-tour
        gnome-weather
        hitori # sudoku game
        iagno # go game
        orca # screen reader
        simple-scan
        tali # poker game
        totem # video player
        yelp
      ];

      systemPackages = with pkgs; [
        gedit
        gnomeExtensions.appindicator
        # clipboard support
        wl-clipboard
      ];
    };
  };
}
