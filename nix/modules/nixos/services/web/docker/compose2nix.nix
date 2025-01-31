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
  exposeLanIP = config.${namespace}.myipv4;
  bridgeSubnet = "172.20.0.0/16";
  bridgeGateway = "172.20.0.1";
in
lib.mkIf config.${namespace}.docker.enable {
  # Runtime
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  ${namespace} = {
    firewall = {
      tcp = [
        7359 # jellyfin
      ];
      udp = [
        51413
        6881
      ];
    };
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
      bazarr = {
        image = "lscr.io/linuxserver/bazarr";
        environment = cfg.defaultEnvironment;
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "${slow}:/data:rw"
          "${fast}/config/bazarr:/config:rw"
        ];
        extraOptions = [
          "--network-alias=bazarr"
          "--network=infra_default"
        ];
        labels = {
          "traefik.http.services.bazarr.loadbalancer.server.port" = "6767";
        };
      };
      deluge = {
        image = "lscr.io/linuxserver/deluge";
        environment = cfg.defaultEnvironment;
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "${fast}/config/deluge:/config:rw"
          "${slow}/downloads:/downloads:rw"
        ];
        ports = [
          "51413:6881/tcp"
          "51413:6881/udp"
        ];
        labels = {
          "traefik.http.services.deluge.loadbalancer.server.port" = "8112";
        };
        extraOptions = [
          "--network-alias=deluge"
          "--network=infra_default"
          # Aren't you RAM hungry sir.
          "--memory=4g"
          "--memory-reservation=3g"
        ];
      };
      # Not strictly necessary, but importantly no pretty way to pass the qb password through cleanly.
      # flood = {
      #   image = "jesec/flood";
      #   environment = cfg.defaultEnvironment;
      #   volumes = [
      #     "/etc/localtime:/etc/localtime:ro"
      #   ];
      #   cmd = [
      #     "--auth=none"
      #     "--qburl=http://qbittorrent:9092"
      #     "--qbuser=admin"
      #     "--qbpass=qbpass"
      #   ];
      #   dependsOn = [
      #     "qbittorrent"
      #   ];
      #   extraOptions = [
      #     "--network-alias=flood"
      #     "--network=infra_default"
      #   ];
      # };

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
      infra-redis-broker = {
        image = "docker.io/library/redis:7";
        volumes = [
          "${fast}/redis:/data:rw"
        ];
        inherit (cfg) user;
        extraOptions = [
          "--network-alias=redis-broker"
          "--network=infra_default"
        ];
        labels = {
          "traefik.enable" = "false";
        };
      };
      jackett = {
        image = "ghcr.io/linuxserver/jackett";
        environment = cfg.defaultEnvironment;
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "${fast}/config/jackett:/config:rw"
        ];
        extraOptions = [
          "--network-alias=jackett"
          "--network=infra_default"
        ];
        labels = {
          "traefik.http.services.jackett.loadbalancer.server.port" = "9127";
        };
      };
      jellyfin = {
        image = "ghcr.io/linuxserver/jellyfin";
        environment = {
          DOCKER_MODS = "linuxserver/mods:jellyfin-opencl-intel";
          JELLYFIN_PublishedServerUrl = "http://jellyfin.lethargy/";
          VERSION = "latest";
        } // cfg.defaultEnvironment;
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "${slow}:/data:ro"
          "${fast}/config/jellyfin:/config:rw"
          "${slow}/transcodes:/config/data/transcodes:rw"
        ];
        ports = [
          "${exposeLanIP}:7359:7359/udp" # service auto-discovery on LAN
        ];
        labels = {
          "traefik.http.services.jellyfin.loadbalancer.server.port" = "8096";
        };
        extraOptions = [
          "--device=/dev/dri/renderD128:/dev/dri/renderD128:rwm"
          "--network-alias=jellyfin"
          "--network=infra_default"
        ];
      };
      jellyseerr = {
        image = "fallenbagel/jellyseerr:latest";
        environment = cfg.defaultEnvironment;
        volumes = [
          "${fast}/config/jellyseerr:/app/config:rw"
        ];
        inherit (cfg) user;
        extraOptions = [
          "--network-alias=jellyseerr"
          "--network=infra_default"
        ];
        labels = {
          "traefik.http.services.jellyseerr.loadbalancer.server.port" = "5055";
        };
      };
      mealie = {
        image = "ghcr.io/mealie-recipes/mealie:v1.0.0-RC2";
        environment = {
          ALLOW_SIGNUP = "true";
          API_DOCS = "False";
          BASE_URL = "https://mealie.home.nicdumz.fr";
          MAX_WORKERS = "1";
          WEB_CONCURRENCY = "1";
        } // cfg.defaultEnvironment;
        volumes = [
          "${fast}/mealie:/app/data:rw"
        ];
        extraOptions = [
          "--memory=1048576000b" # Python unhappy otherwise
          "--network-alias=mealie"
          "--network=infra_default"
        ];
        labels = {
          "traefik.http.services.mealie.loadbalancer.server.port" = "9000";
        };
      };
      # TODO: reenable and fix. Currently it prevents pushes because it's toasted.
      # paperless = {
      #   image = "ghcr.io/paperless-ngx/paperless-ngx:latest";
      #   environment = {
      #     PAPERLESS_DATA_DIR = "/config";
      #     PAPERLESS_MEDIA_ROOT = "/data/media";
      #     PAPERLESS_REDIS = "redis://redis-broker:6379";
      #     PAPERLESS_TIME_ZONE = config.time.timeZone;
      #     PAPERLESS_URL = "https://paperless.home.nicdumz.fr";
      #   } // cfg.defaultEnvironment;
      #   volumes = [
      #     "${fast}/config/paperless:/config:rw"
      #     "${slow}/paperless:/data:rw"
      #   ];
      #   dependsOn = [
      #     "infra-redis-broker"
      #   ];
      #   inherit (cfg) user;
      #   extraOptions = [
      #     "--network-alias=paperless"
      #     "--network=infra_default"
      #   ];
      #   labels = {
      #     "traefik.http.services.paperless.loadbalancer.server.port" = "8000";
      #   };
      # };
      qbittorrent = {
        image = "lscr.io/linuxserver/qbittorrent";
        environment = {
          WEBUI_PORT = "9092";
        } // cfg.defaultEnvironment;
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "${fast}/config/qbittorrent:/config:rw"
          "${slow}/downloads:/downloads:rw"
        ];
        ports = [
          "6881:6881/tcp"
          "6881:6881/udp"
        ];
        labels = {
          "traefik.http.services.qbittorrent.loadbalancer.server.port" = "9092";
        };
        extraOptions = [
          "--network-alias=qbittorrent"
          "--network=infra_default"
        ];
      };
      radarr = {
        image = "ghcr.io/linuxserver/radarr";
        environment = cfg.defaultEnvironment;
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "${slow}:/data:rw"
          "${fast}/config/radarr:/config:rw"
        ];
        dependsOn = [
          "jackett"
          "qbittorrent"
        ];
        extraOptions = [
          "--network-alias=radarr"
          "--network=infra_default"
        ];
        labels = {
          "traefik.http.services.radarr.loadbalancer.server.port" = "7878";
        };
      };
      sonarr = {
        image = "ghcr.io/linuxserver/sonarr";
        environment = cfg.defaultEnvironment;
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "${slow}:/data:rw"
          "${fast}/config/sonarr:/config:rw"
        ];
        dependsOn = [
          "jackett"
          "qbittorrent"
        ];
        extraOptions = [
          "--network-alias=sonarr"
          "--network=infra_default"
        ];
        labels = {
          "traefik.http.services.sonarr.loadbalancer.server.port" = "8989";
        };
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
