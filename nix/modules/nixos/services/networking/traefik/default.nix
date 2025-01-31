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
  staticConf = lib.${namespace}.fromYAML pkgs ./traefik.yml;
  # TODO: the entirety of the config could be in nix, allowing me to remove the docker
  # provider / dependency on the socket entirely
  dynamicConf = lib.${namespace}.fromYAML pkgs ./dynamic.yml;
  additionalDynamicConfig = {
    http =
      let
        # TODO: generate this from some property :-)
        hosts = {
          alertmanager = {
            port = 9093;
          };
          blackbox = {
            port = 9115;
          };
          glance = {
            port = 8081;
            host = "home";
          };
          grafana = {
            port = 3000;
          };
          prometheus = {
            port = 9090;
          };
        };
      in
      {
        middlewares.allowlist.ipAllowList.sourceRange = [
          "${exposeLanIP}/24"
          # TODO: consider adding tailscale network?
        ];

        routers = lib.attrsets.mapAttrs (n: v: {
          rule = "Host(`${v.host or "${n}.home"}.nicdumz.fr`)";
          service = n;
        }) hosts;
        services = lib.attrsets.mapAttrs (_n: v: {
          loadBalancer.servers = [
            { url = "http://127.0.0.1:${toString v.port}"; }
          ];
        }) hosts;
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
  };
  config = lib.mkIf cfg.enable {
    ${namespace} = {
      firewall.tcp = [ 443 ];
      motd.systemdServices = [ "traefik" ];
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
        entryPoints.websecure.address = "${exposeLanIP}:443";
      };
      dynamicConfigOptions = lib.attrsets.recursiveUpdate dynamicConf additionalDynamicConfig;
      environmentFiles = [
        config.sops.secrets.gandi_token_env.path
      ];
    };
  };
}
