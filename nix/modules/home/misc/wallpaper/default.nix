{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.wallpaper;
in
{
  options.${namespace}.wallpaper = {
    path = lib.mkOption {
      type = lib.types.path;
      description = "Path to wallpaper.";
    };
  };

  config = lib.mkIf config.${namespace}.device.isGraphical {
    dconf.settings = {
      "org/gnome/desktop/background" = {
        picture-uri-dark = "file://" + cfg.path;
      };
      "org/gnome/desktop/screensaver" = {
        picture-uri = "file://" + cfg.path;
      };
    };
  };
}
