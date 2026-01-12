{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.jellyfin;
in
{
  options.${namespace}.jellyfin = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Jellyfin: Watch things.";
    };
  };
  config = lib.mkIf cfg.enable {
    hardware.graphics.enable = true;

    services.jellyfin = {
      enable = true;
      group = "media";
    };
    users.groups.media = { };

    # TODO: upstream
    systemd.services.jellyfin.unitConfig.RequiresMountsFor = [
      config.services.jellyfin.configDir
      config.services.jellyfin.logDir
      config.services.jellyfin.cacheDir
    ];
    ${namespace} = {
      motd.systemdServices = [ "jellyfin" ];
      persistence.directories = [
        {
          directory = config.services.jellyfin.configDir;
          user = config.users.users.jellyfin.name;
          group = "media";
        }
        {
          directory = config.services.jellyfin.logDir;
          user = config.users.users.jellyfin.name;
          group = "media";
        }
        {
          directory = config.services.jellyfin.cacheDir;
          user = config.users.users.jellyfin.name;
          group = "media";
        }
      ];
      # unfortunately not exposed in the service config.
      traefik.webservices.jellyfin.port = 8096;
    };
  };
}
