# Auto-generated using compose2nix v0.3.2-pre.
# Note: it's very verbose, not ideal. Just a starting point.
{
  config,
  inputs,
  lib,
  namespace,
  pkgs,
  ...
}:

let
  uid = builtins.toString config.users.users.ndumazet.uid;
  gid = builtins.toString config.users.groups.users.gid;
  # TODO: Will need to move back to fast
  fast = "/media/bigslowdata/dockerstate";
  slow = "/media/bigslowdata";
  # We make a superset of variables to avoid repeating ourselves.
  # It would be nice if all those images could agree on one naming ;-)
  env = {
    PGID = gid;
    GID = gid;
    PUID = uid;
    UID = uid;
    USERMAP_GID = gid;
    USERMAP_UID = uid;
    TZ = config.time.timeZone;
  };
  inherit (config.sops) secrets;
  exposeLanIP = config.${namespace}.myipv4;
  dockerSocket = builtins.head config.virtualisation.docker.listenOptions;
  bridgeSubnet = "172.20.0.0/16";
  bridgeGateway = "172.20.0.1";
in
lib.mkIf config.${namespace}.docker.enable {
  # Runtime
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  ${namespace}.firewall = {
    tcp = [
      443 # traefik
      7359 # jellyfin
      51413 # deluge
      6881 # qbittorrent
    ];
    udp = [
      51413
      6881
    ];
  };

  sops.secrets =
    let
      names = [
        "deadmanssnitch_url"
        "gandi_token_env"
        "prometheus_password"
        "prometheus_username"
        "telegram_token"
      ];
      attrList = builtins.map (
        n:
        lib.attrsets.nameValuePair n {
          sopsFile = inputs.self.outPath + "/secrets/${config.networking.hostName}.yaml";
          owner = "ndumazet";
          group = "users";
        }
      ) names;
    in
    builtins.listToAttrs attrList;

  virtualisation.oci-containers = {

    # TODO: I could probably try moving to podman with virtualisation.podman.dockerSocket.enable on
    backend = "docker";

    # Containers
    containers = {
      alertmanager = {
        image = "prom/alertmanager";
        environment = env;
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "${./config/alertmanager/alertmanager.yml}:/etc/alertmanager/alertmanager.yml:ro"
          "${slow}/dockerstate/alertmanager:/alertmanager:rw"
          # Those paths are expected in alertmanager.yml
          "${secrets.telegram_token.path}:/run/secrets/telegram_token:ro"
          "${secrets.deadmanssnitch_url.path}:/run/secrets/deadmanssnitch:ro"
        ];
        user = "${uid}:${gid}";
        extraOptions = [
          "--network-alias=alertmanager"
          "--network=infra_default"
        ];
        labels = {
          "traefik.http.services.alertmanager.loadbalancer.server.port" = "9093";
        };
      };
      bazarr = {
        image = "lscr.io/linuxserver/bazarr";
        environment = env;
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
      blackbox = {
        image = "prom/blackbox-exporter";
        environment = env;
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          # TODO: this could be a pkgs.writers.writeYAML
          "${./config/blackbox/blackbox.yml}:/config/blackbox.yml:ro"
        ];
        cmd = [ "--config.file=/config/blackbox.yml" ];
        user = "${uid}:${gid}";
        extraOptions = [
          "--dns=8.8.8.8"
          "--network-alias=blackbox"
          "--network=infra_default"
        ];
        labels = {
          "traefik.http.services.blackbox.loadbalancer.server.port" = "9115";
        };
      };
      deluge = {
        image = "lscr.io/linuxserver/deluge";
        environment = env;
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
        ];
      };
      # Not strictly necessary
      # flood = {
      #   image = "jesec/flood";
      #   environment = env;
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
      grafana = {
        image = "grafana/grafana-oss";
        environment = {
          GF_INSTALL_PLUGINS = "grafana-piechart-panel";
          GF_PANELS_DISABLE_SANITIZE_HTML = "true";
        } // env;
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "${fast}/grafana:/var/lib/grafana:rw"
        ];
        user = "${uid}:${gid}";
        extraOptions = [
          "--network-alias=grafana"
          "--network=infra_default"
        ];
        labels = {
          "traefik.http.services.grafana.loadbalancer.server.port" = "3000";
        };
      };
      homarr = {
        image = "ghcr.io/ajnart/homarr:latest";
        environment = {
          DEFAULT_COLOR_SCHEME = "dark";
        } // env;
        volumes = [
          "${fast}/homarr/configs:/app/data/configs:rw"
          "${fast}/homarr/data:/data:rw"
          "${fast}/homarr/icons:/app/public/icons:rw"
          "${dockerSocket}:/var/run/docker.sock:ro"
        ];
        labels = {
          "traefik.http.routers.homarr.rule" = "Host(`home.nicdumz.fr`)";
          "traefik.http.services.homarr.loadbalancer.server.port" = "7575";
        };
        extraOptions = [
          "--network-alias=homarr"
          "--network=infra_default"
        ];
      };
      homeassistant = {
        image = "lscr.io/linuxserver/homeassistant:latest";
        environment = env;
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
        user = "${uid}:${gid}";
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
        environment = env;
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
        } // env;
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
        environment = env;
        volumes = [
          "${fast}/config/jellyseerr:/app/config:rw"
        ];
        user = "${uid}:${gid}";
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
        } // env;
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
      node-exporter = {
        image = "prom/node-exporter:latest";
        volumes = [
          "/:/rootfs:ro"
          "/proc:/host/proc:ro"
          "/sys:/host/sys:ro"
          "/var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket:ro"
        ];
        cmd = [
          "--path.procfs=/host/proc"
          "--path.rootfs=/rootfs"
          "--path.sysfs=/host/sys"
          "--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc|run)($|/)"
          "--collector.systemd"
        ];
        labels = {
          "traefik.enable" = "false";
        };
        extraOptions = [
          "--network-alias=node-exporter"
          "--network=infra_default"
        ];
        labels = {
          "traefik.http.services.node-exporter.loadbalancer.server.port" = "9100";
        };
      };
      paperless = {
        image = "ghcr.io/paperless-ngx/paperless-ngx:latest";
        environment = {
          PAPERLESS_DATA_DIR = "/config";
          PAPERLESS_MEDIA_ROOT = "/data/media";
          PAPERLESS_REDIS = "redis://redis-broker:6379";
          PAPERLESS_TIME_ZONE = config.time.timeZone;
          PAPERLESS_URL = "https://paperless.home.nicdumz.fr";
        } // env;
        volumes = [
          "${fast}/config/paperless:/config:rw"
          "${slow}/paperless:/data:rw"
        ];
        dependsOn = [
          "infra-redis-broker"
        ];
        user = "${uid}:${gid}";
        extraOptions = [
          "--network-alias=paperless"
          "--network=infra_default"
        ];
        labels = {
          "traefik.http.services.paperless.loadbalancer.server.port" = "8000";
        };
      };
      portainer = {
        image = "portainer/portainer-ce:latest";
        environment = env;
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "${fast}/portainer:/data:rw"
          "${dockerSocket}:/var/run/docker.sock:ro"
        ];
        labels = {
          "traefik.http.services.portainer.loadbalancer.server.port" = "9000";
        };
        extraOptions = [
          "--network-alias=portainer"
          "--network=infra_default"
          "--security-opt=no-new-privileges:true"
        ];
      };
      prometheus = {
        image = "prom/prometheus";
        environment = env;
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "${./config/prometheus/prometheus.yml}:/etc/prometheus/prometheus.yml:ro"
          "${./config/prometheus/alerts.yml}:/etc/prometheus/alerts.yml:ro"
          "${fast}/prometheus:/prometheus:rw"
          "${secrets.prometheus_username.path}:/run/secrets/username:ro"
          "${secrets.prometheus_password.path}:/run/secrets/password:ro"
        ];
        cmd = [
          "--config.file=/etc/prometheus/prometheus.yml"
          "--storage.tsdb.path=/prometheus"
          "--storage.tsdb.retention.size=1GB"
          "--storage.tsdb.wal-compression"
          "--web.console.libraries=/usr/share/prometheus/console_libraries"
          "--web.console.templates=/usr/share/prometheus/consoles"
        ];
        user = "${uid}:${gid}";
        extraOptions = [
          "--add-host=host.docker.internal:host-gateway"
          "--network-alias=prometheus"
          "--network=infra_default"
        ];
        labels = {
          "traefik.http.services.prometheus.loadbalancer.server.port" = "9090";
        };
      };
      qbittorrent = {
        image = "lscr.io/linuxserver/qbittorrent";
        environment = {
          WEBUI_PORT = "9092";
        } // env;
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
        environment = env;
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
        environment = env;
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
          "traefik.http.services.sonarr.loadbalancer.server.port" = "7878";
        };
      };
      traefik = {
        image = "traefik";
        environment = env;
        environmentFiles = [
          # Contains an env-like file.
          secrets.gandi_token_env.path
        ];
        volumes =
          let
            # TODO: all could be in nix...
            conf = lib.${namespace}.fromYAML pkgs ./config/traefik/dynamic.yml;
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
            "${./config/traefik/traefik.yml}:/etc/traefik/traefik.yml:ro"
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
      # Disable: I would prefer explicit updates.
      # watchtower = {
      #   image = "containrrr/watchtower";
      #   environment = env;
      #   environmentFiles = [ secrets.watchtower_env.path ];
      #   volumes = [
      #     "/etc/localtime:/etc/localtime:ro"
      #     "${dockerSocket}:/var/run/docker.sock:ro"
      #   ];
      #   cmd = [
      #     "--schedule"
      #     "0 5 3 * * *"
      #     "--cleanup"
      #     "--notifications-level"
      #     "error"
      #   ];
      #   labels = {
      #     "traefik.enable" = "false";
      #   };
      #   extraOptions = [
      #     "--network-alias=watchtower"
      #     "--network=infra_default"
      #   ];
      # };
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
