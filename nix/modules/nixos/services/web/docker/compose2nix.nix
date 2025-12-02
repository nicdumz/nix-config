# Auto-generated using compose2nix v0.3.2-pre.
# Note: it's very verbose, not ideal. Just a starting point.
{
  config,
  lib,
  namespace,
  pkgs,
  ...
}:

let
  cfg = config.${namespace}.containers;
  inherit (cfg.dataroot) fast;
  inherit (cfg.dataroot) slow;
  bridgeSubnet = "172.20.0.0/16";
  bridgeGateway = "172.20.0.1";
  calibreIngest = "${slow}/downloads/calibre";
in
lib.mkIf config.${namespace}.docker.enable {
  # Runtime
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  ${namespace} = {
    persistence.directories = [ config.virtualisation.docker.daemon.settings.data-root ];

    motd.systemdServices = lib.attrsets.mapAttrsToList (
      n: _v: "docker-" + n
    ) config.virtualisation.oci-containers.containers;
  };

  virtualisation.oci-containers = {

    # TODO: I could probably try moving to podman with virtualisation.podman.dockerSocket.enable on
    backend = "docker";

    # Containers
    containers = {
      # Technically this is calibre-web-automated.
      calibreweb = {
        image = "crocodilestick/calibre-web-automated:latest";
        environment = cfg.defaultEnvironment;
        # may need as well:
        # HARDCOVER_TOKEN=your_hardcover_api_key_here
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "${fast}/config/calibre-web:/config:rw"
          "${calibreIngest}:/cwa-book-ingest"
          "${slow}/books:/calibre-library"
        ];
        extraOptions = [
          "--network-alias=calibreweb"
          "--network=infra_default"
        ];
        labels = {
          "traefik.http.services.calibreweb.loadbalancer.server.port" = "8083";
        };
      };
      calibredownloader = {
        image = "ghcr.io/calibrain/calibre-web-automated-book-downloader:latest";
        environment = {
          USE_BOOK_TITLE = "true";
          APP_ENV = "prod";
        }
        // cfg.defaultEnvironment;
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "${calibreIngest}:/cwa-book-ingest"
        ];
        extraOptions = [
          "--network-alias=calibredownloader"
          "--network=infra_default"
        ];
        labels = {
          "traefik.http.services.calibredownloader.loadbalancer.server.port" = "8084";
        };
      };
      # TODO: Include the following as /config/configuration.yaml
      /*
        # Loads default set of integrations. Do not remove.
        default_config:

        api:
        http:
          use_x_forwarded_for: true
          trusted_proxies:
            - 172.20.0.0/24
      */
      homeassistant = {
        image = "lscr.io/linuxserver/homeassistant:latest";
        environment = cfg.defaultEnvironment;
        volumes = [
          "${fast}/config/homeassistant:/config:rw"
        ];
        extraOptions = [
          "--dns=127.0.0.1"
          "--network-alias=homeassistant"
          "--network=infra_default"
        ];
        labels = {
          "traefik.http.services.homeassistant.loadbalancer.server.port" = "8123";
        };
      };
      watchtower = {
        image = "containrrr/watchtower";
        environment = cfg.defaultEnvironment;
        extraOptions = [
          "--network-alias=watchtower"
          "--network=infra_default"
        ];
        volumes = [
          "${builtins.head config.virtualisation.docker.listenOptions}:/var/run/docker.sock"
        ];
        # Update every 8 hours.
        cmd = [ "--interval=21600" ];
      };
    };
  };

  systemd.services =
    let
      sConfig = {
        serviceConfig = {
          Restart = lib.mkOverride 90 "always";
          RestartMaxDelaySec = lib.mkOverride 90 "1m";
          RestartSec = lib.mkOverride 90 "100ms";
          RestartSteps = lib.mkOverride 90 9;
        };
        after = [ "docker-network-infra_default.service" ];
        requires = [ "docker-network-infra_default.service" ];
        partOf = [ "docker-compose-infra-root.target" ];
        wantedBy = [ "docker-compose-infra-root.target" ];
      };
      func = lib.attrsets.mapAttrs' (n: _v: lib.attrsets.nameValuePair ("docker-" + n) sConfig);
    in
    func config.virtualisation.oci-containers.containers
    // {
      # Networks
      "docker-network-infra_default" = {
        path = [ pkgs.docker ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStop = "docker network rm -f infra_default";
        };
        script = ''
          docker network inspect infra_default || docker network create infra_default --subnet=${bridgeSubnet} --gateway=${bridgeGateway} -o "com.docker.network.bridge.name"="docker-bridge"
        '';
        partOf = [ "docker-compose-infra-root.target" ];
        wantedBy = [ "docker-compose-infra-root.target" ];
      };
    };

  # Root service
  # When started, this will automatically create all resources and start
  # the containers. When stopped, this will teardown all resources.
  systemd.targets.docker-compose-infra-root = {
    unitConfig = {
      Description = "Root target generated by compose2nix.";
    };
    wantedBy = [ "multi-user.target" ];
  };
}
