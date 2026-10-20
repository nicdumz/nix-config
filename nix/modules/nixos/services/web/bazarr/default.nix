{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.bazarr;
in
{
  options.${namespace}.bazarr = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Bazarr: subtitles.";
    };
  };
  config = lib.mkIf cfg.enable {
    services.bazarr = {
      enable = true;
      group = "media";
      listenPort = 6768;
    };
    # Pinned: dynamic uids/gids are not stable across userborn runs with
    # mutableUsers = false, and this user/group own persisted state.
    users.users.bazarr.uid = 999;
    users.groups.media.gid = 995;

    ${namespace} = {
      motd.systemdServices = [ "bazarr" ];
      traefik.webservices.bazarr.port = config.services.bazarr.listenPort;
      persistence.directories = [
        {
          directory = config.services.bazarr.dataDir;
          inherit (config.services.bazarr) user group;
        }
      ];
    };
  };
}
