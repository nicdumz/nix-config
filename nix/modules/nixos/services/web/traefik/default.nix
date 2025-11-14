{
  config,
  inputs,
  lib,
  namespace,
  pkgs,
  ...
}:
let
  cfg = config.${namespace}.traefik;

  exposeLanIP = config.${namespace}.myipv4;
  dockerSocket = builtins.head config.virtualisation.docker.listenOptions;
  staticConf = lib.${namespace}.readYAML pkgs ./traefik.yml;
  # TODO: the entirety of the config could be in nix, allowing me to remove the docker
  # provider / dependency on the socket entirely
  dynamicConf = lib.${namespace}.readYAML pkgs ./dynamic.yml;
  additionalDynamicConfig = {
    http = {
      middlewares.allowlist.ipAllowList.sourceRange = [
        "${exposeLanIP}/24"
        # TODO: consider adding tailscale network?
      ];

      routers = lib.attrsets.mapAttrs (n: v: {
        rule = "Host(`${if v.host != "" then v.host else "${n}.home"}.nicdumz.fr`)";
        service = n;
      }) cfg.webservices;
      services = lib.attrsets.mapAttrs (_n: v: {
        loadBalancer.servers = [
          { url = "http://127.0.0.1:${toString v.port}"; }
        ];
      }) cfg.webservices;
    };
  };
in
{
  options.${namespace}.traefik = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable traefik reverse proxy.";
    };

    webservices = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            host = lib.mkOption {
              type = lib.types.strMatching "((.+\.)?home)?";
              description = "Host to use. Unset/empty default means: use `<attrname>.home`.";
              default = "";
            };
            port = lib.mkOption {
              type = lib.types.port;
            };
          };
        }
      );
      description = "web services to reverse proxy to. This is additional to auto-discovery via docker provider";
    };
  };

  config = lib.mkIf cfg.enable {
    ${namespace} = {
      firewall.tcp = [ 443 ];
      motd.systemdServices = [ "traefik" ];
      persistence.directories = [
        {
          directory = config.services.traefik.dataDir;
          user = "traefik";
          group = "traefik";
        }
      ];
    };
    users.groups.docker.members = [ "traefik" ];

    sops.secrets.gandi_token_env = {
      sopsFile = inputs.self.outPath + "/secrets/${config.networking.hostName}.yaml";
      owner = "traefik";
      group = "nogroup";
    };

    services.traefik = {
      enable = true;
      staticConfigOptions = lib.attrsets.recursiveUpdate staticConf {
        providers.docker.endpoint = "unix://${dockerSocket}";
        # TODO: add Ipv6 ULA?
        entryPoints.websecure.address = "${exposeLanIP}:443";
      };
      dynamicConfigOptions = lib.attrsets.recursiveUpdate dynamicConf additionalDynamicConfig;
      environmentFiles = [
        config.sops.secrets.gandi_token_env.path
      ];
    };
  };
}
