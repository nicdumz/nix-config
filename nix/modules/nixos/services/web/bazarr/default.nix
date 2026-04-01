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
    users.groups.media = { };

    # TODO: in-progress-upstream (26.05)
    systemd.services.bazarr.unitConfig.RequiresMountsFor = [ config.services.bazarr.dataDir ];
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
