{
  config,
  namespace,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  graphicalCatppuccin = lib.mkIf config.${namespace}.device.isGraphical {
    enable = true;
    cursors.enable = pkgs.stdenv.hostPlatform.isLinux;
    waybar.enable = false;
    # image = config.${namespace}.wallpaper.path;
    # polarity = "dark";
    # targets = {
    #   fish.colors.enable = false;
    #   kitty.colors.enable = false;
    #   neovim.colors.enable = false;
    #   starship.colors.enable = false;
    # };
    # base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    # fonts = {
    #   monospace = {
    #     inherit (config.fontProfiles.monospace) name;
    #     inherit (config.fontProfiles.monospace) package;
    #   };
    #   # serif = {
    #   #   name = config.fontProfiles.regular.name;
    #   #   package = config.fontProfiles.regular.pkg;
    #   # };
    #   # sansSerif = {
    #   #   name = config.fontProfiles.regular.name;
    #   #   package = config.fontProfiles.regular.pkg;
    #   # };
    #   sizes = {
    #     applications = 12;
    #     terminal = 12;
    #     desktop = 11;
    #     popups = 12;
    #   };
    # };
  };
in
{
  imports = [ inputs.catppuccin.homeModules.catppuccin ];

  # catppuccin/nix warns on every eval unless `autoEnable` has been explicitly
  # set *somewhere*, regardless of which branch of `graphicalCatppuccin`'s
  # `mkIf` is taken -- so this must stay unconditional, not nested inside it.
  catppuccin = lib.mkMerge [
    { autoEnable = config.catppuccin.enable; }
    graphicalCatppuccin
  ];
}
