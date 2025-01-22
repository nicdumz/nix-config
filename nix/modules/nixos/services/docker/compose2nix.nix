# Auto-generated using compose2nix v0.3.2-pre.
# Note: it's very verbose, not ideal. Just a starting point.
{
  config,
  hostname,
  inputs,
  lib,
  namespace,
  pkgs,
  ...
}:

let
  user = config.users.users.ndumazet.uid;
  group = config.users.groups.users.gid;
  # TODO: Will need to move back to fast
  fast = "/media/bigslowdata/dockerstate";
  slow = "/media/bigslowdata";
  # We make a superset of variables to avoid repeating ourselves.
  env = {
    PGID = group;
    GID = group;
    PUID = user;
    UID = user;
    USERMAP_GID = group;
    USERMAP_UID = user;
    TZ = config.time.timezone;
  };
  inherit (config.sops) secrets;
in
lib.mkIf config.${namespace}.docker.enable {
  # Runtime
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  sops.secrets =
    let
      names = [
        "deadmansnitch_url"
        "gandi_token_env"
        "telegram_token"
        "watchtower_env"
      ];
      attrList = builtins.map (
        n:
        lib.attrsets.nameValuePair n {
          sopsFile = inputs.self.outPath + "/secrets/${hostname}.yaml";
          owner = user;
          inherit group;
        }
      ) names;
    in
    builtins.listToAttrs attrList;

  virtualisation.oci-containers = {

    backend = "docker";

    # Containers
    containers = {
      alertmanager = {
        image = "prom/alertmanager";
        environment = env;
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "TODO/config/alertmanager:/etc/alertmanager:ro"
          "${slow}/dockerstate/alertmanager:/alertmanager:rw"
          # Those paths are expected in alertmanager.yml
          "${secrets.telegram_token.path}:/run/secrets/telegram_token:ro"
          "${secrets.deadmansnitch_url.path}:/run/secrets/deadmansnitch:ro"
        ];
        inherit user;
        extraOptions = [
          "--network-alias=alertmanager"
          "--network=infra_default"
        ];
        ports = [ "127.0.0.1:9093:9093" ];
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
        ports = [ "127.0.0.1:6767:6767" ];
      };
      blackbox = {
        image = "prom/blackbox-exporter";
        environment = env;
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "TODO/config/prometheus:/config:ro"
        ];
        cmd = [ "--config.file=/config/blackbox.yml" ];
        inherit user;
        extraOptions = [
          "--dns=8.8.8.8"
          "--network-alias=blackbox"
          "--network=infra_default"
        ];
        ports = [ "127.0.0.1:9115:9115" ];
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
          "127.0.0.1:8112:8112"
        ];
        labels = {
          "traefik.http.services.deluge.loadbalancer.server.port" = 8112;
        };
        extraOptions = [
          "--network-alias=deluge"
          "--network=infra_default"
        ];
      };
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
      #  ports = [ "127.0.0.1:3000:3000" ];
      # };
      grafana = {
        image = "grafana/grafana-oss";
        environment = {
          GF_INSTALL_PLUGINS = "grafana-piechart-panel";
          GF_PANELS_DISABLE_SANITIZE_HTML = true;
        } // env;
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "${fast}/grafana:/var/lib/grafana:rw"
        ];
        inherit user;
        extraOptions = [
          "--network-alias=grafana"
          "--network=infra_default"
        ];
        ports = [ "127.0.0.1:3000:3000" ];
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
          "/var/run/docker.sock:/var/run/docker.sock:ro"
        ];
        labels = {
          "traefik.http.routers.homarr.rule" = "Host(`home.nicdumz.fr`)";
        };
        extraOptions = [
          "--network-alias=homarr"
          "--network=infra_default"
        ];
        ports = [ "127.0.0.1:7575:7575" ];
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
        ports = [ "127.0.0.1:8123:8123" ];
      };
      infra-redis-broker = {
        image = "docker.io/library/redis:7";
        volumes = [
          "${fast}/redis:/data:rw"
        ];
        user = "${user}:${group}";
        extraOptions = [
          "--network-alias=redis-broker"
          "--network=infra_default"
        ];
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
        ports = [ "127.0.0.1:9117:9117" ];
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
          "127.0.0.1:8096:8096/tcp"
          "192.168.1.1:7359:7359/udp" # service auto-discovery on LAN
        ];
        labels = {
          "traefik.http.services.jellyfin.loadbalancer.server.port" = 8096;
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
        user = "${user}:${group}";
        extraOptions = [
          "--network-alias=jellyseerr"
          "--network=infra_default"
        ];
        ports = [ "127.0.0.1:5055:5055" ];
      };
      mealie = {
        image = "ghcr.io/mealie-recipes/mealie:v1.0.0-RC2";
        environment = {
          ALLOW_SIGNUP = "true";
          API_DOCS = "False";
          BASE_URL = "https://mealie.home.nicdumz.fr";
          MAX_WORKERS = 1;
          WEB_CONCURRENCY = 1;
        } // env;
        volumes = [
          "${fast}/mealie:/app/data:rw"
        ];
        extraOptions = [
          "--memory=1048576000b" # Python unhappy otherwise
          "--network-alias=mealie"
          "--network=infra_default"
        ];
        ports = [ "127.0.0.1:9000:9000" ];
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
          "traefik.enable" = false;
        };
        extraOptions = [
          "--network-alias=node-exporter"
          "--network=infra_default"
        ];
        ports = [ "127.0.0.1:9100:9100" ];
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
        user = "${user}:${group}";
        extraOptions = [
          "--network-alias=paperless"
          "--network=infra_default"
        ];
        ports = [ "127.0.0.1:8000:8000" ];
      };
      portainer = {
        image = "portainer/portainer-ce:latest";
        environment = env;
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "${fast}/portainer:/data:rw"
          "/var/run/docker.sock:/var/run/docker.sock:ro"
        ];
        labels = {
          "traefik.http.services.portainer.loadbalancer.server.port" = 9000;
        };
        ports = [ "127.0.0.1:9000:9000" ];
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
          "TODO/config/prometheus:/etc/prometheus:ro"
          "${fast}/prometheus:/prometheus:rw"
        ];
        cmd = [
          "--config.file=/etc/prometheus/prometheus.yml"
          "--storage.tsdb.path=/prometheus"
          "--storage.tsdb.retention.size=1GB"
          "--storage.tsdb.wal-compression"
          "--web.console.libraries=/usr/share/prometheus/console_libraries"
          "--web.console.templates=/usr/share/prometheus/consoles"
        ];
        inherit user;
        extraOptions = [
          "--add-host=host.docker.internal:host-gateway"
          "--network-alias=prometheus"
          "--network=infra_default"
        ];
        ports = [ "127.0.0.1:9090:9090" ];
      };
      qbittorrent = {
        image = "lscr.io/linuxserver/qbittorrent";
        environment = {
          WEBUI_PORT = 9092;
        } // env;
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "${fast}/config/qbittorrent:/config:rw"
          "${slow}/downloads:/downloads:rw"
        ];
        ports = [
          "6881:6881/tcp"
          "6881:6881/udp"
          "127.0.0.1:9092:9092"
        ];
        labels = {
          "traefik.http.services.qbittorrent.loadbalancer.server.port" = 9092;
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
        ports = [ "127.0.0.1:7878:7878" ];
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
        ports = [ "127.0.0.1:8989:8989" ];
      };
      traefik = {
        image = "traefik";
        environment = env;
        environmentFiles = [
          # Contains an env-like file.
          secrets.gandi_token_env.path
        ];
        volumes = [
          "TODO/config/traefik:/etc/traefik:ro"
          "${fast}/traefik:/data:rw"
          # TODO: do we need this?
          # "/usr/share/zoneinfo:/usr/share/zoneinfo:ro"
          "/var/run/docker.sock:/var/run/docker.sock:ro"
        ];
        ports = [
          "192.168.1.1:443:443"
          "127.0.0.1:8080:8080"
        ];
        labels = {
          "traefik.enable" = false;
        };
        extraOptions = [
          "--network-alias=traefik"
          "--network=infra_default"
        ];
      };
      watchtower = {
        image = "containrrr/watchtower";
        environment = env;
        environmentFiles = [ secrets.watchtower_env.file ];
        volumes = [
          "/etc/localtime:/etc/localtime:ro"
          "/var/run/docker.sock:/var/run/docker.sock:ro"
        ];
        cmd = [
          "--schedule"
          "0 5 3 * * *"
          "--cleanup"
          "--notifications-level"
          "error"
        ];
        labels = {
          "traefik.enable" = false;
        };
        extraOptions = [
          "--network-alias=watchtower"
          "--network=infra_default"
        ];
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
          docker network inspect infra_default || docker network create infra_default
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
