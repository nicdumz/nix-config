{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.jackett;
in
{
  options.${namespace}.jackett = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Jackett: indexing.";
    };
  };
  config = lib.mkIf cfg.enable {
    services.jackett = {
      enable = true;
      group = "media";
    };
    users.groups.media = { };

    ${namespace} = {
      motd.systemdServices = [ "jackett" ];
      traefik.webservices.jackett.port = config.services.jackett.port;
      persistence.directories = [
        {
          directory = config.services.jackett.dataDir;
          inherit (config.services.jackett) user;
          inherit (config.services.jackett) group;
        }
      ];
    };
  };
}
