{
  config,
  inputs,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.pocketid;
in
{
  options.${namespace}.pocketid = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Pocket ID";
    };
    port = lib.mkOption {
      type = lib.types.int;
      default = 1411;
    };
  };
  config = lib.mkIf cfg.enable {
    services.pocket-id = {
      enable = true;
      settings = {
        APP_URL = "https://id.home.nicdumz.fr";
        HOST = "127.0.0.1";
        PORT = "${builtins.toString cfg.port}";
        TRUST_PROXY = true; # behind Traefik
        MAXMIND_LICENSE_KEY_FILE = config.sops.secrets.maxmind-license-key.path;
        ENCRYPTION_KEY_FILE = config.sops.secrets.pocket-id-secret.path;
      };
    };
    sops.secrets.pocket-id-secret = {
      sopsFile = inputs.self.outPath + "/secrets/${config.networking.hostName}.yaml";
      owner = config.users.users.pocket-id.name;
      inherit (config.users.users.nobody) group;
    };
    sops.secrets.maxmind-license-key = {
      sopsFile = inputs.self.outPath + "/secrets/${config.networking.hostName}.yaml";
      owner = config.users.users.pocket-id.name;
      inherit (config.users.users.nobody) group;
    };

    ${namespace} = {
      persistence.directories = [
        {
          directory = config.services.pocket-id.dataDir;
          user = config.users.users.pocket-id.name;
          inherit (config.users.users.pocket-id) group;
        }
      ];
      motd.systemdServices = [ "pocket-id" ];
      traefik.webservices.pocket-id = {
        inherit (cfg) port;
        host = "id.home"; # id.home.nicdumz.fr
      };
    };
  };
}
