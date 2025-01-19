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
  config = lib.mkIf cfg.enable {
    services.blocky.enable = true;
    networking.resolvconf.useLocalResolver = true;
    # No need to start before network.
    systemd.services.blocky.after = [ "network-online.target" ];
    systemd.services.blocky.wants = [ "network-online.target" ];
    services.blocky.settings = {
      bootstrapDns = [
        {
          upstream = "tcp-tls:dns.quad9.net";
          ips = [
            "9.9.9.9"
            "149.112.112.112"
            "2620:fe::fe"
            "2620:fe::9"
          ];
        }
      ];
      upstreams.groups.default = [ "tcp-tls:dns.quad9.net" ];
      customDNS = {
        customTTL = "1m";
        mapping = {
          lethargy = "192.168.1.1";
          "jonsnow.local" = "192.168.1.1";
          bistannix = "192.168.1.42";
          "home.nicdumz.fr" = "192.168.1.1";
        };
      };
      caching.prefetching = true;
      # queryLog:
      #   type: mysql
      #   target: blocky:blocky@tcp(mysql:3306)/blocky?charset=utf8mb4&parseTime=True&loc=Local
      #   logRetentionDays: 7
      # TODO: consider changing that.
      ports.http = 4000;
      prometheus.enable = true;
      blocking = {
        # NOTE: blocking was disabled for a while.
        clientGroupsBlock.default = [
          "ads"
          "suspicious"
          "tracking"
        ];
        # https://firebog.net/ was useful here
        allowLists = {
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
              dns.msftncsi.com''
          ];
        };
        denyLists = {
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
}
