{
  config,
  lib,
  namespace,
  inputs,
  ...
}:
let
  cfg = config.${namespace}.traefik;

  exposeLanIP = config.${namespace}.myipv4;

  # Individual OIDC:
  # - mealie
  # - jellyfin (but allow TV...)
  # - jellyseerr would need https://github.com/seerr-team/seerr/issues/183 or preview-OIDC branch
  # - paperless
  # - (grafana, but lost server admin)
  # - (pangolin)

  # Put behind an OIDC proxy (maybe oauth2-proxy):
  # - radarr/bazarr/sonarr/prowlarr: disable auth first
  # - victorialogs
  # - traefik? (but open API for pangolin? first)
  # - homeassistant (disable auth at https://www.home-assistant.io/docs/authentication/providers/ )
  # - qbittorrent (and disable auth / local ips)
  # - alertmanager
  # - blackbox
  # - ddns-updater?

  # Other:
  # - grocy: set ReverseProxyAuthMiddleware and pass the right header

  dynamicConfig = {
    http = {
      middlewares = {
        allowlist.ipAllowList.sourceRange = [
          "${exposeLanIP}/24"
          # TODO: consider adding tailscale network?
        ];
        cors.headers = {
          accessControlAllowMethods = [
            "GET"
            "HEAD"
            "OPTIONS"
            "PUT"
          ];
          accessControlAllowCredentials = true;
          accessControlAllowHeaders = "*";
          accessControlAllowOriginListRegex = [ ".*\.home\.nicdumz\.fr" ];
          addVaryHeader = true;
        };
      };

      routers =
        (lib.attrsets.mapAttrs (n: v: {
          rule = "Host(`${if v.host != "" then v.host else "${n}.home"}.nicdumz.fr`)";
          service = n;
        }) cfg.webservices)
        // {
          traefik = {
            rule = "Host(`traefik.home.nicdumz.fr`)";
            service = "api@internal";
            middlewares = [ "allowlist" ];
          };
        };
      services = lib.attrsets.mapAttrs (_n: v: {
        loadBalancer.servers = [
          { url = "http://127.0.0.1:${toString v.port}"; }
        ];
      }) cfg.webservices;
    }; # / http

    tls.stores.default.defaultGeneratedCert = {
      resolver = "letsencrypt";
      domain = {
        main = "*.home.nicdumz.fr";
        sans = [ "home.nicdumz.fr" ];
      };
    };
  };

  staticConfig = {
    api = {
      dashboard = true;
      debug = false;
    };
    ping.entryPoint = "traefik"; # default, equivalent to ping {}
    metrics.prometheus.addEntryPointsLabels = true;
    # Overridden from :8080 which listens on all IPs.
    entryPoints.traefik.address = "127.0.0.1:8080";
    entryPoints.websecure = {
      # TODO: add Ipv6 ULA?
      # Pangolin module tries to listen on all interfaces, do not let it.
      address = lib.mkForce "${exposeLanIP}:443";
      http = {
        middlewares = [ "cors@file" ];
        tls.certResolver = "letsencrypt";
      };
    };
    # Verbose traffic log so I can debug
    accesslog.format = "common"; # default, equivalent to accessLog {}
    # NOTE: this matches pangolin naming/configs
    certificatesResolvers.letsencrypt.acme = {
      email = "nicdumz@gmail.com";
      # Pangolin module is silly and tries to override this.
      storage = lib.mkForce "/var/lib/traefik/acme.json";
      dnsChallenge = {
        provider = "cloudflare";
        # TODO: is that needed?
        # # Not sure, Gandi is making my life challenging (?)
        # propagation.disableANSChecks = true;
        # Blocky otherwise would mask the actual Gandi record.
        resolvers = [
          "1.1.1.1:53"
          "8.8.8.8:53"
        ];
      };
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
      description = "web services to reverse proxy to.";
    };
  };

  config = lib.mkIf cfg.enable {
    ${namespace} = {
      firewall.tcp = [ 443 ];
      motd.systemdServices = [ "traefik" ];
      persistence.directories = [
        {
          directory = config.services.traefik.dataDir;
          user = config.users.users.traefik.name;
          inherit (config.users.users.traefik) group;
        }
      ];
    };

    sops.secrets.cloudflare-dns-api-token = {
      sopsFile = inputs.self.outPath + "/secrets/${config.networking.hostName}.yaml";
    };

    sops.templates.cloudflare-dns-api-token-env.content = "CLOUDFLARE_DNS_API_TOKEN=${config.sops.placeholder.cloudflare-dns-api-token}";

    services.traefik = {
      enable = true;
      # Enabling pangolin messes up with this default
      dataDir = lib.mkForce "/var/lib/traefik";
      staticConfigOptions = staticConfig;
      dynamicConfigOptions = dynamicConfig;
      environmentFiles = [
        config.sops.templates.cloudflare-dns-api-token-env.path
      ];
    };
  };
}
