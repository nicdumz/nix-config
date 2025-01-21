{
  config,
  lib,
  namespace,
  osConfig ? { },
  ...
}:
let
  cfg = config.${namespace}.librewolf;
in
{
  options.${namespace}.librewolf = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Librewolf browser for this user.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs.librewolf = lib.optionalAttrs (osConfig.${namespace}.graphical or false) {
      enable = true;
      settings =
        let
          ext = name: "https://addons.mozilla.org/firefox/downloads/latest/${name}/latest.xpi";
        in
        {
          # Note: those are only overrides on top of relatively reasonable librewolf defaults.
          # If librewolf strays away, I could/should extend this list.
          "webgl.disabled" = false;
          "dom.security.https_only_mode_ever_enabled" = true;
          "browser.policies.runOncePerModification.setDefaultSearchEngine" = "DuckDuckGo";
          "browser.policies.runOncePerModification.extensionsInstall" =
            "[${(ext "ublock-origin")}, ${(ext "bitwarden-password-manager")}]";
          "font.name.monospace.x-western" = config.fontProfiles.monospace.name;
          "font.minimum-size.x-western" = config.fontProfiles.monospace.size;
        };
    };

    xdg = {
      mimeApps = {
        enable = true;
        defaultApplications = {
          "text/html" = "librewolf.desktop";
          "x-scheme-handler/http" = "librewolf.desktop";
          "x-scheme-handler/https" = "librewolf.desktop";
          "x-scheme-handler/about" = "librewolf.desktop";
          "x-scheme-handler/unknown" = "librewolf.desktop";
        };
      };
    };
  };
}
