{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.prowlarr;
in
{
  options.${namespace}.prowlarr = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Prowlarr: indexing.";
    };
  };
  config = lib.mkIf cfg.enable {
    services.prowlarr.enable = true;

    users.groups.media = { };
    users.users.prowlarr = {
      description = "Services needs a user but doesn't explicitly create it.";
      group = "media";
      isSystemUser = true;
    };

    # TODO: in-progress-upstream (26.05)
    systemd.services.prowlarr = {
      unitConfig.RequiresMountsFor = [ config.services.prowlarr.dataDir ];
      serviceConfig.DynamicUser = lib.mkForce false;
    };
    ${namespace} = {
      motd.systemdServices = [ "prowlarr" ];
      traefik.webservices.prowlarr.port = config.services.prowlarr.settings.server.port;
      persistence.directories = [
        {
          directory = config.services.prowlarr.dataDir;
          user = config.users.users.prowlarr.name;
          inherit (config.users.users.prowlarr) group;
        }
      ];
    };
  };
}
