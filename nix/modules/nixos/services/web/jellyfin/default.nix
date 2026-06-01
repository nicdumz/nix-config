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
    # For hardware rendering
    users.users.jellyfin.extraGroups = [
      "render"
      "video"
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
          # One of them must create the parent /var/lib/jellyfin in /persist and /
          configureParent = true;
          parent = {
            inherit (config.services.jellyfin) user group;
          };
        }
        {
          directory = config.services.jellyfin.cacheDir;
          inherit (config.services.jellyfin) user group;
        }
      ];
      # unfortunately not exposed in the service config.
      traefik.webservices.jellyfin.port = 8096;
    };
  };
}
