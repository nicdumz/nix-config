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
      mediaDir = "/media/bigslowdata/paperless";
      address = "127.0.0.1";
      passwordFile = config.sops.secrets.paperless-admin-password.path;
      settings.PAPERLESS_ADMIN_USER = "ndumazet";
      settings.PAPERLESS_URL = "https://paperless.home.nicdumz.fr";
      # Daily export to ${dataDir}/export (persisted), then uploaded off-site by restic below.
      # Briefly stops paperless services while running.
      exporter = {
        enable = true;
        onCalendar = "02:00:00";
        settings = {
          use-folder-prefix = true;
          split-manifest = true;
        };
      };
    };

    # Off-site copy of the export into the GCS bucket gs://jonsnow-backups (project jonsnow-backups,
    # Standard storage class). No pruning: every snapshot is kept; the repo grows only by deduped changes.
    services.restic.backups.paperless = {
      paths = [ config.services.paperless.exporter.directory ];
      repository = "gs:jonsnow-backups:/paperless";
      passwordFile = config.sops.secrets.restic-password.path;
      initialize = true;
      # Triggered by paperless-exporter on success instead of a timer.
      timerConfig = null;
    };
    systemd.services.restic-backups-paperless.environment = {
      GOOGLE_PROJECT_ID = "jonsnow-backups";
      GOOGLE_APPLICATION_CREDENTIALS = config.sops.secrets.restic-gcs-credentials.path;
    };
    systemd.services.paperless-exporter.unitConfig.OnSuccess = [ "restic-backups-paperless.service" ];

    sops.secrets =
      let
        sopsFile = inputs.self.outPath + "/secrets/${config.networking.hostName}.yaml";
      in
      {
        paperless-admin-password = {
          owner = config.users.users.paperless.name;
          inherit sopsFile;
        };
        restic-password = { inherit sopsFile; };
        restic-gcs-credentials = { inherit sopsFile; };
      };

    ${namespace} = {
      motd.systemdServices = [ "paperless-web" ];
      persistence.directories = [
        {
          directory = config.services.paperless.dataDir;
          user = config.users.users.paperless.name;
          inherit (config.users.users.paperless) group;
        }
      ];
      traefik.webservices.paperless.port = config.services.paperless.port;
    };
  };
}
