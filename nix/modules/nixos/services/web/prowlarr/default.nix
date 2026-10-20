{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.prowlarr;
in
{
  options.${namespace}.prowlarr = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Prowlarr: indexing.";
    };
  };
  config = lib.mkIf cfg.enable {
    services.prowlarr.enable = true;

    # Pinned: dynamic uids/gids are not stable across userborn runs with
    # mutableUsers = false, and this user/group own persisted state.
    users.groups.media.gid = 995;
    users.users.prowlarr = {
      description = "Services needs a user but doesn't explicitly create it.";
      group = "media";
      isSystemUser = true;
      uid = 988;
    };

    systemd.services.prowlarr = {
      serviceConfig.DynamicUser = lib.mkForce false;
      # Without an explicit User, disabling DynamicUser leaves this running as root.
      serviceConfig.User = config.users.users.prowlarr.name;
    };
    ${namespace} = {
      motd.systemdServices = [ "prowlarr" ];
      traefik.webservices.prowlarr.port = config.services.prowlarr.settings.server.port;
      persistence.directories = [
        {
          directory = config.services.prowlarr.dataDir;
          user = config.users.users.prowlarr.name;
          inherit (config.users.users.prowlarr) group;
        }
      ];
    };
  };
}
