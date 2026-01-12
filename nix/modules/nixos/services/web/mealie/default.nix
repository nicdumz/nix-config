{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.mealie;
  dataDir = "/var/lib/mealie";
in
{
  options.${namespace}.mealie = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Mealie: selfhosted recipes.";
    };
  };
  config = lib.mkIf cfg.enable {
    services.mealie = {
      enable = true;
      listenAddress = "127.0.0.1";
      # settings.BASE_URL = "https://mealie.home.nicdumz.fr/";
      settings.DATA_DIR = dataDir;
    };
    users.users.mealie = {
      description = "Services needs a user but doesn't explicitly create it.";
      group = "mealie";
      isSystemUser = true;
    };
    users.groups.mealie = { };
    systemd.services.mealie = {
      unitConfig.RequiresMountsFor = [ dataDir ];
      serviceConfig.DynamicUser = lib.mkForce false;
    };

    ${namespace} = {
      motd.systemdServices = [ "mealie" ];
      persistence.directories = [
        {
          directory = dataDir;
          user = config.users.users.mealie.name;
          inherit (config.users.users.mealie) group;
        }
      ];
      traefik.webservices.mealie.port = config.services.mealie.port;
    };
  };
}
