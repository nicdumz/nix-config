{
  config,
  lib,
  namespace,
  osConfig ? { },
  pkgs,
  ...
}:
let
  cfg = config.${namespace}.chrome;
in
{
  options.${namespace}.chrome = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Chrome for this user.";
    };
  };

  config = lib.mkIf (cfg.enable && (osConfig.${namespace}.graphical or false)) {
    # Due to Chrome in G's profile.
    # TODO: move to unfree module.
    nixpkgs.config.allowUnfree = true;
    home.packages = [
      pkgs.google-chrome
    ];
  };
}
