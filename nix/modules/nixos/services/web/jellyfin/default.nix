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
    # Pinned: dynamic uids/gids are not stable across userborn runs with
    # mutableUsers = false, and this user/group own persisted state.
    users.groups.media.gid = 995;
    users.users.jellyfin = {
      uid = 980;
      # For hardware rendering
      extraGroups = [
        "render"
        "video"
      ];
    };

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
