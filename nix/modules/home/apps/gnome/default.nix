{
  config,
  osConfig ? { },
  lib,
  namespace,
  ...
}:
{
  dconf.settings =
    let
      r = config.fontProfiles.regular;
      m = config.fontProfiles.monospace;
      rf = "${r.name} ${toString r.size}";
      mf = "${m.name} ${toString m.size}";
    in
    lib.optionalAttrs (osConfig.${namespace}.graphical or false) {
      # Fractional scaling.
      "org/gnome/mutter" = {
        experimental-features = [ "scale-monitor-framebuffer" ];
      };
      "org/gnome/desktop/interface" = {
        scaling-factor = lib.home-manager.hm.gvariant.mkUint32 0;
        text-scaling-factor = lib.home-manager.hm.gvariant.mkDouble (
          osConfig.${namespace}.scaling.factor or 1.0
        );
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
}
