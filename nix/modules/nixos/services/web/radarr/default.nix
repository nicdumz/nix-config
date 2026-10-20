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
    # Pinned: dynamic gids are not stable across userborn runs with
    # mutableUsers = false, and this group owns persisted state.
    users.groups.media.gid = 995;

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
