{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.vector;
in
{
  options.${namespace}.vector = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Vector log agent. Pulls logs from journald.";
    };
  };
  config =
    let
      inherit (config.${namespace}) loki;
    in
    lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = loki.enable;
          message = "Loki must be enabled as well.";
        }
      ];

      systemd.services.vector.after = [ "loki.service" ];
      systemd.services.vector.wants = [ "loki.service" ];

      services.vector = {
        enable = true;
        journaldAccess = true;

        settings = {
          # This is the default but helps me remember ;-)
          data_dir = "/var/lib/vector";

          sources = {
            # Full options at https://vector.dev/docs/reference/configuration/sources/journald/
            systemlog = {
              type = "journald";
            };
            # TODO: Docker?
          };
          sinks = {
            # console_out = {
            #   type = "console";
            #   inputs = ["systemlog"];
            #   encoding.codec = "text";
            # };
            loki = {
              type = "loki";
              inputs = [ "systemlog" ];
              endpoint = "http://${loki.bindAddress}:${builtins.toString loki.port}";
              encoding.codec = "json";
              labels.logsource = "systemlog";
            };
          };
        };
      };
    };
}
