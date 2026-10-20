{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.jellyseerr;
in
{
  options.${namespace}.jellyseerr = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Seerr: request downloads.";
    };
  };
  config = lib.mkIf cfg.enable {
    services.seerr = {
      enable = true;
    };
    # Pinned: dynamic uids/gids are not stable across userborn runs with
    # mutableUsers = false, and this user/group own persisted state.
    users.users.jellyseerr = {
      description = "Services needs a user but doesn't explicitly create it.";
      group = "jellyseerr";
      isSystemUser = true;
      uid = 996;
    };
    users.groups.jellyseerr.gid = 998;

    systemd.services.seerr = {
      serviceConfig.DynamicUser = lib.mkForce false;
      serviceConfig.User = config.users.users.jellyseerr.name;
    };

    ${namespace} = {
      motd.systemdServices = [ "seerr" ];
      persistence.directories = [
        {
          directory = config.services.seerr.configDir;
          user = config.users.users.jellyseerr.name;
          inherit (config.users.users.jellyseerr) group;
        }
      ];
      traefik.webservices.seerr.port = config.services.seerr.port;
    };
    systemd.tmpfiles.settings.preservation = {
      "/var/lib/jellyseerr".d = {
        user = config.users.users.jellyseerr.name;
        inherit (config.users.users.jellyseerr) group;
      };
    };
  };
}
