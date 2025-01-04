{ config, pkgs, ... }:
{
  services.xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;

    # Configure keymap in X11
    xkb.layout = "us";
    # xkb.options = "eurosign:e,caps:escape";
  };

  environment.gnome.excludePackages = with pkgs; [
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
  services.udev.packages = [ pkgs.gnome-settings-daemon ];

  # Enable sound.
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  environment.systemPackages = with pkgs; [
    gedit
    gnomeExtensions.appindicator
    # clipboard support
    (lib.mkIf config.services.xserver.enable xsel)
    (lib.mkIf (!config.services.xserver.enable) wl-copy)
  ];

  fonts.packages = [
    pkgs.cascadia-code
  ];
  fonts.fontconfig.enable = true;
}
