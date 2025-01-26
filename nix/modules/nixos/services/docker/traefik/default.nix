{
  config,
  lib,
  pkgs,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.containers;
  inherit (cfg.dataroot) fast;
  exposeLanIP = config.${namespace}.myipv4;
  dockerSocket = builtins.head config.virtualisation.docker.listenOptions;
  bridgeGateway = "172.20.0.1";
in
lib.mkIf config.${namespace}.docker.enable {
  ${namespace}.firewall.tcp = [ 443 ];

  virtualisation.oci-containers.containers.traefik = {
    image = "traefik";
    environment = cfg.defaultEnvironment;
    environmentFiles = [
      # Contains an env-like file.
      config.sops.secrets.gandi_token_env.path
    ];
    volumes =
      let
        # TODO: the entirety of the config could be in nix, allowing me to remove the docker
        # provider / dependency on the socket entirely
        conf = lib.${namespace}.fromYAML pkgs ./dynamic.yml;
        final = lib.attrsets.recursiveUpdate conf {
          http.middlewares.allowlist.ipAllowList.sourceRange = [
            # "${exposeLanIP}/24"
            # "127.0.0.1"
            # All traffic appears to come from the bridge.
            bridgeGateway
            # TODO: consider adding tailscale network?
          ];
        };
        dynamicFile = pkgs.writers.writeYAML "dynamic.yml" final;
      in
      [
        "${dynamicFile}:/etc/traefik/dynamic.yml:ro"
        "${./traefik.yml}:/etc/traefik/traefik.yml:ro"
        # TODO: is it possible to adapt the above to become a directory link?
        # "something/config/traefik:/etc/traefik:ro"
        "${fast}/traefik:/data:rw"
        # TODO: do we need this?
        # "/usr/share/zoneinfo:/usr/share/zoneinfo:ro"
        "${dockerSocket}:/var/run/docker.sock:ro"
      ];
    ports = [
      "${exposeLanIP}:443:443"
    ];
    labels = {
      "traefik.enable" = "false";
    };
    extraOptions = [
      "--network-alias=traefik"
      "--network=infra_default"
    ];
  };
}
