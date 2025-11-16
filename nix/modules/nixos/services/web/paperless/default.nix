{
  config,
  inputs,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.paperless;
in
{
  options.${namespace}.paperless = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Paperless document archiving.";
    };
  };
  config = lib.mkIf cfg.enable {
    services.paperless = {
      enable = true;
      # TODO: I want this backed up properly
      mediaDir = "/media/bigslowdata/paperless";
      address = "127.0.0.1";
      passwordFile = config.sops.secrets.paperless-admin-password.path;
      settings.PAPERLESS_ADMIN_USER = "ndumazet";
      settings.PAPERLESS_URL = "https://paperless.home.nicdumz.fr";
    };

    sops.secrets.paperless-admin-password = {
      owner = config.users.users.grafana.name;
      sopsFile = inputs.self.outPath + "/secrets/${config.networking.hostName}.yaml";
    };

    ${namespace} = {
      motd.systemdServices = [ "paperless-web" ];
      persistence.directories = [
        {
          # TODO: db.sqlite3 in this directory is the file needing backup.
          directory = config.services.paperless.dataDir;
          user = config.users.users.grafana.name;
          inherit (config.users.users.grafana) group;
        }
      ];
      traefik.webservices.paperless.port = config.services.paperless.port;
    };
  };
}
