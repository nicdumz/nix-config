{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.sonarr;
in
{
  options.${namespace}.sonarr = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Radarr: series.";
    };
  };
  config = lib.mkIf cfg.enable {
    services.sonarr = {
      enable = true;
      group = "media";
      settings.server.port = 7879;
    };
    # Pinned: dynamic gids are not stable across userborn runs with
    # mutableUsers = false, and this group owns persisted state.
    users.groups.media.gid = 995;

    ${namespace} = {
      motd.systemdServices = [ "sonarr" ];
      traefik.webservices.sonarr.port = config.services.sonarr.settings.server.port;
      persistence.directories = [
        {
          directory = config.services.sonarr.dataDir;
          inherit (config.services.sonarr) user group;
        }
      ];
    };
  };
}
