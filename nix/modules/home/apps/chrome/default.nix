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
    home.packages = [
      pkgs.google-chrome
    ];

    xdg = {
      mimeApps = {
        enable = true;
        defaultApplications = {
          "application/pdf" = "google-chrome.desktop";
          "text/html" = "google-chrome.desktop";
          "x-scheme-handler/http" = "google-chrome.desktop";
          "x-scheme-handler/https" = "google-chrome.desktop";
          "x-scheme-handler/about" = "google-chrome.desktop";
          "x-scheme-handler/unknown" = "google-chrome.desktop";
        };
      };
    };
  };
}
