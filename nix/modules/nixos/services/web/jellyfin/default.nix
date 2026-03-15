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
          inherit (config.services.jellyfin) user group;
        }
        {
          directory = config.services.jellyfin.logDir;
          inherit (config.services.jellyfin) user group;
        }
        {
          directory = config.services.jellyfin.cacheDir;
          inherit (config.services.jellyfin) user group;
        }
      ];
      # unfortunately not exposed in the service config.
      traefik.webservices.jellyfin.port = 8096;
    };
    # Parent needs to exist with correct permissions but no need to preserve all of it.
    systemd.tmpfiles.settings.preservation.${config.services.jellyfin.dataDir}.d = {
      inherit (config.services.jellyfin) user group;
    };
  };
}
