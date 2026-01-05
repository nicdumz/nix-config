{
  config,
  lib,
  namespace,
  ...
}:
let
  cfg = config.${namespace}.blocky;
in
{
  options.${namespace}.blocky = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable blocky DNS server.";
    };
  };
  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      networking.resolvconf.useLocalResolver = true;
      networking.nameservers = [
        "127.0.0.1"
        "::1"
      ];

      # TODO: why is this even enabled in the first place...
      services.resolved.enable = false;

      # No need to start before network.
      systemd.services.blocky = {
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        serviceConfig.LogsDirectory = "blocky";
      };

      ${namespace} = {
        motd.systemdServices = [ "blocky" ];

        firewall = {
          udp = [ 53 ];
          tcp = [ 53 ];
        };
      };

      services.blocky = {
        enable = true;
        settings = {
          connectIPVersion = "v4";
          bootstrapDns = [
            {
              upstream = "https://one.one.one.one/dns-query";
              ips = [
                "1.1.1.1"
                "1.0.0.1"
              ];
            }
            {
              upstream = "https://dns.quad9.net/dns-query";
              ips = [
                "9.9.9.9"
                "149.112.112.112"
              ];
            }
          ];
          upstreams.groups.default = [
            "https://one.one.one.one/dns-query"
            "https://dns.quad9.net/dns-query"
          ];
          upstreams.timeout = "2s";
          customDNS = {
            customTTL = "1m";
            mapping = {
              "home.nicdumz.fr" = config.${namespace}.myipv4;
            };
          };
          caching.prefetching = true;
          queryLog = {
            type = "csv";
            logRetentionDays = 7;
            target = "/var/log/blocky"; # created by systemd unit
          };
          ports = {
            dns = [
              "${config.${namespace}.myipv4}:53"
              "127.0.0.1:53"
              # TODO: consider binding to an ULA instead of all ipv6
              "[::1]:53"
            ];
            http = "127.0.0.1:4000";
          };
          ede.enable = true;
          prometheus.enable = true;
          blocking = {
            # NOTE: blocking was disabled for a while.
            clientGroupsBlock.default = [
              "ads"
              "suspicious"
              "tracking"
            ];
            # https://firebog.net/ was useful here
            allowlists = {
              ads = [
                # inline definition of hosts to allow
                ''
                  bit.ly
                  bnc.lt
                  cdn.optimizely.com
                  ow.ly
                  s.shopify.com
                  t.ly
                  tinyurl.com
                  www.bit.ly
                  # https://github.com/StevenBlack/hosts/issues/1206 sigh both insta and
                  # tracking
                  graph.instagram.com
                  # this is what M$ uses to phone home / check connectivity
                  dns.msftncsi.com
                  # OK -- can I configure analytics myself? Sigh.
                  analytics.google.com
                ''
              ];
            };
            denylists = {
              suspicious = [
                "https://raw.githubusercontent.com/PolishFiltersTeam/KADhosts/master/KADhosts.txt"
                "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.Spam/hosts"
                "https://v.firebog.net/hosts/static/w3kbl.txt"
              ];
              ads = [
                "https://adaway.org/hosts.txt"
                "https://v.firebog.net/hosts/AdguardDNS.txt"
                "https://v.firebog.net/hosts/Admiral.txt"
                "https://raw.githubusercontent.com/anudeepND/blacklist/master/adservers.txt"
                "https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt"
                "https://v.firebog.net/hosts/Easylist.txt"
              ];
              tracking = [
                "https://v.firebog.net/hosts/Easyprivacy.txt"
                "https://v.firebog.net/hosts/Prigent-Ads.txt"
                "https://raw.githubusercontent.com/FadeMind/hosts.extras/master/add.2o7Net/hosts"
              ];
              malware = [
                "https://raw.githubusercontent.com/DandelionSprout/adfilt/master/Alternate%20versions%20Anti-Malware%20List/AntiMalwareHosts.txt"
                "https://osint.digitalside.it/Threat-Intel/lists/latestdomains.txt"
                "https://s3.amazonaws.com/lists.disconnect.me/simple_malvertising.txt"
                "https://v.firebog.net/hosts/Prigent-Crypto.txt"
              ];
            };
          };
        };
      };
    })
    (lib.mkIf (!cfg.enable) {
      services.resolved = {
        # This lets resolved listen on ipv6 on localhost, which makes `dig -6` simply work in the
        # presence of /etc/resolv.conf forwarding to systemd-resolved
        # I feel like this should be the default, and this doesn't really have to be in this config,
        # but ... sue me ;-)
        extraConfig = ''
          DNSStubListenerExtra=[::1]:53
        '';
      };
    })
  ];
}
