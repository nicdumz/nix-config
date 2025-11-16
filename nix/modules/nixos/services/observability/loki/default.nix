{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.loki;
in
{
  options.${namespace}.loki = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Loki.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      # TODO: fine but what is happening on port 9095, mm, what is this.
      default = 3100;
      readOnly = true;
    };
    bindAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.bindAddress != "";
        message = "Bind address must be set.";
      }
    ];
    # Not persisting this directory would mean that we lose logs on reboots,
    # which perhaps isn't the worst but for now I've decided to keep those
    # across reboots.
    ${namespace}.persistence.directories = [
      {
        directory = config.services.loki.dataDir;
        user = config.users.users.loki.name;
        inherit (config.users.users.loki) group;
      }
    ];

    services.grafana.provision.datasources.settings.datasources = [
      {
        name = "Loki";
        type = "loki";
        access = "proxy";
        url = "http://${cfg.bindAddress}:${builtins.toString cfg.port}";
      }
    ];

    services.loki = {
      enable = true;
      configuration = {
        auth_enabled = false;

        server.http_listen_port = cfg.port;
        server.http_listen_address = cfg.bindAddress;

        # Tssk tssk you don't need to report "stats" centrally.
        # See also https://github.com/NixOS/nixpkgs/issues/378277
        analytics.reporting_enabled = false;

        common = {
          ring = {
            instance_addr = cfg.bindAddress;
            kvstore.store = "inmemory";
          };
          storage.filesystem = {
            chunks_directory = "chunks";
            rules_directory = "rules";
          };
          replication_factor = 1;
          path_prefix = "/var/lib/loki";
        };

        # The following limits log history to 10d
        compactor.retention_enabled = true;
        compactor.delete_request_store = "filesystem";
        limits_config.retention_period = "240h";

        schema_config.configs = [
          {
            from = "1970-01-01";
            store = "tsdb";
            object_store = "filesystem";
            schema = "v13";
            index.prefix = "index_";
            index.period = "24h";
          }
        ];
      };
    };
  };
}
