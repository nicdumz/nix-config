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
