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
      description = "Jellyseerr: request downloads.";
    };
  };
  config = lib.mkIf cfg.enable {
    services.jellyseerr = {
      enable = true;
    };
    users.users.jellyseerr = {
      description = "Services needs a user but doesn't explicitly create it.";
      group = "jellyseerr";
      isSystemUser = true;
    };
    users.groups.jellyseerr = { };

    systemd.services.jellyseerr = {
      serviceConfig.DynamicUser = lib.mkForce false;
      serviceConfig.User = config.users.users.jellyseerr.name;
      # TODO: upstream
      unitConfig.RequiresMountsFor = config.services.jellyseerr.configDir;
    };

    ${namespace} = {
      motd.systemdServices = [ "jellyseerr" ];
      persistence.directories = [
        {
          directory = config.services.jellyseerr.configDir;
          user = config.users.users.jellyseerr.name;
          inherit (config.users.users.jellyseerr) group;
        }
      ];
      traefik.webservices.jellyseerr.port = config.services.jellyseerr.port;
    };
  };
}
