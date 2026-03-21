{
  config,
  lib,
  namespace,
  inputs,
  ...
}:
let
  cfg = config.${namespace}.pangolin;
in
{
  options.${namespace}.pangolin = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Pangolin";
    };
  };
  config = lib.mkIf cfg.enable {
    services.pangolin = {
      enable = true;
      baseDomain = "home.nicdumz.fr";
      # It's a bit strange to duplicate this with traefik config,
      # the pangolin module could be better.
      dnsProvider = "cloudflare";
      letsEncryptEmail = "nicdumz@gmail.com";
      settings = {
        app = {
          log_failed_attempts = true;
        };
        flags = {
          disable_signup_without_invite = true;
          disable_user_create_org = true;
        };
        server.external_port = 2999;
        # looks like a silly example config but the pangolin module config
        # uses this to figure it if wildcard certs should be used :/
        domains.domain1 = {
          prefer_wildcard_cert = true;
        };
        traefik = {
          cert_resolver = "letsencrypt";
          prefer_wildcard_cert = true;
        };
      };
      environmentFile = config.sops.templates.pangolin-env.path;
    };
    ${namespace} = {
      persistence.directories = [
        {
          directory = config.services.pangolin.dataDir;
          user = config.users.users.pangolin.name;
          inherit (config.users.users.pangolin) group;
        }
      ];
      # Maybe add gerbil too
      motd.systemdServices = [ "pangolin" ];
    };
    sops.secrets.pangolin-secret = {
      sopsFile = inputs.self.outPath + "/secrets/${config.networking.hostName}.yaml";
      owner = config.users.users.pangolin.name;
      inherit (config.users.users.pangolin) group;
    };
    sops.templates.pangolin-env.content = "SERVER_SECRET=${config.sops.placeholder.pangolin-secret}";
  };
}
