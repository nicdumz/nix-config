{
  config,
  inputs,
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

      provision = {
        enable = true;
        datasources.settings = {
          apiVersion = 1;
          # I let other modules add here
          datasources = [ ];
        };
      };

      settings = {
        server.domain = "grafana.home.nicdumz.fr";
        # Note to self, default is already:
        # server.http_addr = "127.0.0.1";
        # server.http_port = 3000
        security.admin_password = "$__file{${config.sops.secrets.grafana-admin-password.path}}";
      };
    };

    ${namespace}.motd.systemdServices = [ "grafana" ];

    sops.secrets.grafana-admin-password = {
      owner = "grafana";
      sopsFile = inputs.self.outPath + "/secrets/${config.networking.hostName}.yaml";
    };
  };
}
