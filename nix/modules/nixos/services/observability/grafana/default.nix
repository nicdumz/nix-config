{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.grafana;
in
{
  options.${namespace}.grafana = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Grafana on host.";
    };
  };
  # Note: I used to have:
  # GF_INSTALL_PLUGINS = "grafana-piechart-panel";
  # GF_PANELS_DISABLE_SANITIZE_HTML = "true";
  # enabled in docker, need to check if useful
  config = lib.mkIf cfg.enable {
    services.grafana = {
      enable = true;

      # Note to self, default is already:
      # settings.server.http_addr = "127.0.0.1";
      provision = {
        enable = true;
        datasources.settings = {
          apiVersion = 1;
          # I let other modules add here
          datasources = [ ];
        };
      };
    };
  };
}
