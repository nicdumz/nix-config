# Module common to all homes / users.
{
  lib,
  inputs,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ./fish.nix
    ./fonts.nix
    ./neovim.nix
  ];

  programs.home-manager.enable = true;
  home.homeDirectory = lib.mkDefault "/home/${config.home.username}";
  home.stateVersion = "24.11";

  # For nixd
  nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

  programs.htop.enable = true;

  dconf.settings =
    let
      r = config.fontProfiles.regular;
      m = config.fontProfiles.monospace;
      rf = "${r.name} ${toString r.size}";
      mf = "${m.name} ${toString m.size}";
    in
    {
      "org/gnome/desktop/interface" = {
        scaling-factor = lib.hm.gvariant.mkUint32 2;
        text-scaling-factor = lib.hm.gvariant.mkDouble 2.0;
        cursor-size = 36;
        color-scheme = "prefer-dark";
        document-font-name = rf;
        font-name = rf;
        monospace-font-name = mf;
      };
      "org/gnome/desktop/wm/preferences" = {
        titlebar-font = rf;
      };
      "org/gnome/desktop/background" = {
        picture-uri-dark = "file://" + ./nixos-wallpaper.png;
      };
      "org/gnome/desktop/screensaver" = {
        picture-uri = "file://" + ./nixos-wallpaper.png;
      };
    };

  xdg.enable = true;

  programs.eza = {
    enable = true;
    icons = "auto";
    colors = "auto";
  };

  programs.git = {
    enable = true;
    aliases = {
      st = "status";
      ci = "commit";
      glog = "log --graph --decorate --branches=*";
    };
    extraConfig = {
      github.user = "nicdumz";
      "url \"git@github.com:\"".pushInsteadOf = "https://github.com/";
    };
  };
}
