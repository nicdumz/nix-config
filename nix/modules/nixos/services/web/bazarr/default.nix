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

    ${namespace} = {
      motd.systemdServices = [ "bazarr" ];
      traefik.webservices.bazarr.port = config.services.bazarr.listenPort;
      persistence.directories = [
        {
          directory = "/var/lib/bazarr";
          # directory = config.users.users.bazarr.home;
          user = config.users.users.bazarr.name;
          inherit (config.services.bazarr) group;
        }
      ];
    };
  };
}
