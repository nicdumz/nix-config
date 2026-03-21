{
  config,
  inputs,
  namespace,
  lib,
  ...
}:
let
  cfg = config.${namespace}.ddns-updater;
in
{
  options.${namespace}.ddns-updater = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable ddns-updater.";
    };
    domains = lib.mkOption {
      type = lib.types.str;
      default = "*.home.nicdumz.fr,home.nicdumz.fr";
    };
    port = lib.mkOption {
      type = lib.types.int;
      default = 8005;
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.cloudflare-dns-api-token = {
      sopsFile = inputs.self.outPath + "/secrets/${config.networking.hostName}.yaml";
    };

    sops.templates.ddns-config.content = ''
      {
        "settings": [
          {
            "provider": "cloudflare",
            "zone_identifier": "686bd156340822f7200d83d81db673c9",
            "ttl": 1,
            "domain": "${cfg.domains}",
            "token": "${config.sops.placeholder.cloudflare-dns-api-token}",
            "ip_version": "ipv4"
          },
          {
            "provider": "cloudflare",
            "zone_identifier": "686bd156340822f7200d83d81db673c9",
            "ttl": 1,
            "domain": "${cfg.domains}",
            "token": "${config.sops.placeholder.cloudflare-dns-api-token}",
            "ip_version": "ipv6"
          }
        ]
      }
    '';
    services.ddns-updater = {
      enable = true;
      environment = {
        RESOLVER_ADDRESS = "1.1.1.1:53";
        CONFIG_FILEPATH = "%d/conf";
        LISTENING_ADDRESS = "127.0.0.1:${toString cfg.port}";
      };
    };
    systemd.services.ddns-updater.serviceConfig.LoadCredential =
      "conf:${config.sops.templates.ddns-config.path}";

    ${namespace} = {
      motd.systemdServices = [ "ddns-updater" ];
      traefik.webservices.ddns-updater = {
        inherit (cfg) port;
      };
    };
  };
}
