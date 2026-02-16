{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.victorialogs;
in
{
  options.${namespace}.victorialogs = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Victoria Logs ingestion. Pulls logs from journald.";
    };
    port = lib.mkOption {
      type = lib.types.int;
      default = 9428;
    };
  };
  config = lib.mkIf cfg.enable {
    services = {
      victorialogs.enable = true;
      victorialogs.listenAddress = "127.0.0.1:${builtins.toString cfg.port}";
      journald.upload.enable = true;
      journald.upload.settings.Upload.URL =
        "http://${config.services.victorialogs.listenAddress}/insert/journald";
    };

    users.users.victorialogs = {
      description = "Services needs a user but doesn't explicitly create it.";
      group = "victorialogs";
      isSystemUser = true;
    };
    users.groups.victorialogs = { };

    systemd.services.victorialogs = {
      serviceConfig.DynamicUser = lib.mkForce false;
      serviceConfig.User = config.users.users.victorialogs.name;
    };

    ${namespace} = {
      persistence.directories = [
        {
          directory = "/var/lib/${config.services.victorialogs.stateDir}";
          user = config.users.users.victorialogs.name;
          inherit (config.users.users.victorialogs) group;
        }
      ];
      motd.systemdServices = [ "victorialogs" ];
      traefik.webservices.victorialogs = {
        inherit (cfg) port;
      };
    };
  };
}
