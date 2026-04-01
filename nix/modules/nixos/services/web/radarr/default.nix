{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.radarr;
in
{
  options.${namespace}.radarr = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Radarr: movies.";
    };
  };
  config = lib.mkIf cfg.enable {
    services.radarr = {
      enable = true;
      group = "media";
      settings.server.port = 8990;
    };
    users.groups.media = { };

    # TODO: in-progress-upstream (26.05)
    systemd.services.radarr.unitConfig.RequiresMountsFor = [ config.services.radarr.dataDir ];
    ${namespace} = {
      motd.systemdServices = [ "radarr" ];
      traefik.webservices.radarr.port = config.services.radarr.settings.server.port;
      persistence.directories = [
        {
          directory = config.services.radarr.dataDir;
          inherit (config.services.radarr) user group;
        }
      ];
    };
  };
}
