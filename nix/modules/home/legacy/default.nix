# Module common to all homes / users.
{
  config,
  osConfig ? { },
  inputs,
  lib,
  namespace,
  ...
}:
{
  imports = [
    ./fish.nix
    ./fonts.nix
    ./neovim.nix
  ];

  programs.home-manager.enable = true;
  # home.homeDirectory = lib.mkDefault "/home/${config.home.username}";
  home.stateVersion = "24.11";

  # For nixd
  nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

  dconf.settings =
    let
      r = config.fontProfiles.regular;
      m = config.fontProfiles.monospace;
      rf = "${r.name} ${toString r.size}";
      mf = "${m.name} ${toString m.size}";
    in
    lib.optionalAttrs (osConfig.${namespace}.graphical or false) {
      "org/gnome/desktop/interface" = {
        scaling-factor = lib.home-manager.hm.gvariant.mkUint32 0;
        text-scaling-factor = lib.home-manager.hm.gvariant.mkDouble 1.25;
        cursor-size = 24;
        color-scheme = "prefer-dark";
        document-font-name = rf;
        font-name = rf;
        monospace-font-name = mf;
      };
      "org/gnome/desktop/wm/preferences" = {
        titlebar-font = rf;
      };
    };

  xdg.enable = true;
}
