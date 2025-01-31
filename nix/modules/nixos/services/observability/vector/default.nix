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
      systemd.services.vector.requires = [ "loki.service" ];
      ${namespace}.motd.systemdServices = [ "vector" ];

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
          };
          transforms = {
            processed_journald = {
              type = "remap";
              inputs = [ "systemlog" ];
              source = ''
                # delete fields I don't find useful
                del(.CONTAINER_ID_FULL)
                del(.CONTAINER_ID)
                del(.CONTAINER_LOG_EPOCH)
                del(.CONTAINER_TAG)
                del(.SYSLOG_FACILITY)
                del(.SYSLOG_PID)
                del(.SYSLOG_TIMESTAMP)
                del(._AUDIT_LOGINUID)
                del(._AUDIT_SESSION)
                del(._BOOT_ID)
                del(._CAP_EFFECTIVE)
                del(._CMDLINE)
                del(._COMM)
                del(._EXE)
                del(._GID)
                del(._MACHINE_ID)
                del(._PID)
                del(._SELINUX_CONTEXT)
                del(._SOURCE_MONOTONIC_TIMESTAMP)
                del(._SOURCE_REALTIME_TIMESTAMP)
                del(._STREAM_ID)
                del(._SYSTEMD_CGROUP)
                del(._SYSTEMD_INVOCATION_ID)
                del(._SYSTEMD_OWNER_UID)
                del(._SYSTEMD_SESSION)
                del(._SYSTEMD_SLICE)
                del(._SYSTEMD_USER_SLICE)
                del(._TRANSPORT)
                del(._UID)
                del(.__MONOTONIC_TIMESTAMP)
                del(.__SEQNUM)
                del(.__SEQNUM_ID)
                del(.source_type)
                del(.timestamp)

                if !exists(._SYSTEMD_UNIT) {
                  ._SYSTEMD_UNIT = "unknown"
                }
                .body = del(.)
                .service_name = del(.body.SYSLOG_IDENTIFIER)
                .systemd_scope = del(.body._RUNTIME_SCOPE)
                .systemd_unit = del(.body._SYSTEMD_UNIT)
                .timestamp_nanos = del(.body.__REALTIME_TIMESTAMP)
                .container = del(.body.CONTAINER_NAME)

                # parse priority
                .severity_text = if includes(["0", "1", "2", "3"], .body.PRIORITY) {
                  "ERROR"
                } else if .body.PRIORITY == "4" {
                  "WARN"
                } else if .body.PRIORITY == "7" {
                  "DEBUG"
                } else if includes(["6"], .body.PRIORITY) {
                  "INFO"
                } else {
                  "NOTICE"
                }
                del(.body.PRIORITY)

                # deal with firewall messages
                if .service_name == "kernel" {
                  p, err = parse_regex(.body.message, r'refused connection: (?P<packet>.*)')
                  if err == null {
                    .packet = parse_key_value!(p.packet)
                    .body.message = "refused connection"
                    .service_name = "firewall"
                  }
                }
              '';
            };
          };
          sinks = {
            loki = {
              type = "loki";
              inputs = [ "processed_journald" ];
              endpoint = "http://${loki.bindAddress}:${builtins.toString loki.port}";
              encoding.codec = "json";
              labels = {
                service_name = "{{service_name}}";
                unit = "{{systemd_unit}}";
                severity = "{{severity_text}}";
                firewall_in = "{{packet.IN}}";
                firewall_out = "{{packet.OUT}}";
                host = "{{body.host}}";
              };
            };
          };
        };
      };
    };
}
