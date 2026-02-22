{
  config,
  namespace,
  inputs,
  pkgs,
  osConfig ? { },
  lib,
  ...
}:
{
  imports = [ inputs.stylix.homeModules.stylix ];

  stylix = lib.mkIf (osConfig.${namespace}.graphical or false) {
    enable = true;
    image = config.${namespace}.wallpaper.path;
    polarity = "dark";
    targets = {
      fish.colors.enable = false;
      kitty.colors.enable = false;
      neovim.colors.enable = false;
      starship.colors.enable = false;
    };
    base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
    fonts = {
      monospace = {
        inherit (config.fontProfiles.monospace) name;
        inherit (config.fontProfiles.monospace) package;
      };
      # serif = {
      #   name = config.fontProfiles.regular.name;
      #   package = config.fontProfiles.regular.pkg;
      # };
      # sansSerif = {
      #   name = config.fontProfiles.regular.name;
      #   package = config.fontProfiles.regular.pkg;
      # };
      sizes = {
        applications = 12;
        terminal = 12;
        desktop = 11;
        popups = 12;
      };
    };
  };
}
