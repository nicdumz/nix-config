{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace} = {
    networkmap = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            mac = lib.mkOption {
              type = lib.types.strMatching "([[:xdigit:]]{2}:){5}[[:xdigit:]]{2}";
              description = "MAC address";
              default = null;
            };
            ip = lib.mkOption {
              # Trusted LAN (192.168.1.0/24) or IoT VLAN (192.168.20.0/24).
              type = lib.types.strMatching "192\.168\.(1|20)\.[[:digit:]]{1,3}";
              description = "IPv4 local address";
              default = null;
            };
          };
        }
      );
      description = "Network map.";
    };
    myipv4 = lib.mkOption {
      type = lib.types.str;
      default = config.${namespace}.networkmap.${config.networking.hostName}.ip;
    };
    myipv6 = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Stable IPv6 address (ULA) of this host on the LAN, if any.";
    };
  };

  config.${namespace}.networkmap = {
    jonsnow = {
      ip = "192.168.1.1";
    };
    usw-mini = {
      mac = "74:ac:b9:ab:b7:34";
      ip = "192.168.1.2";
    };
    # XGS1250-12
    zyxel-switch = {
      mac = "70:49:A2:4A:82:16";
      ip = "192.168.1.3";
    };
    # NWA130BE
    zyxel-ap = {
      mac = "bc:7e:c3:56:3b:fc";
      ip = "192.168.1.4";
    };
    # jonsnow-admin0 =
    # {
    #   # this is the admin0 port
    #   mac = "a8:a1:59:92:8f:9d";
    #   ip = "192.168.1.5";
    # }

    pikvm = {
      mac = "e4:5f:01:4c:f8:24";
      ip = "192.168.1.11";
    };

    bistannix = {
      mac = "f0:2f:74:79:de:79";
      ip = "192.168.1.42";
    };
    traboule = {
      mac = "10:e7:c6:34:de:74";
      ip = "192.168.1.43";
    };
    lethargyfamily = {
      mac = "e4:c7:67:52:f7:4c";
      ip = "192.168.1.44";
    };

    # IoT VLAN (20): internet + DNS only, see jonsnow's firewall. Static leases kept outside the
    # dynamic pool (.50-.149).
    chromecastgoogletv = {
      mac = "14:c1:4e:01:b3:21";
      ip = "192.168.20.10";
    };
    # The Samsung TV itself, distinct from the Chromecast above.
    samsung-tv = {
      mac = "00:7d:3b:7b:18:3a";
      ip = "192.168.20.12";
    };
    sonos-living-room = {
      mac = "5c:aa:fd:a1:a9:40";
      ip = "192.168.20.20";
    };
    sonos-kitchen = {
      mac = "00:0e:58:7c:8a:5e";
      ip = "192.168.20.21";
    };
    # RIPE Atlas hardware probe (TP-Link based); only needs the internet.
    ripe-atlas = {
      mac = "64:66:b3:d1:17:22";
      ip = "192.168.20.30";
    };
    elgato-keylight = {
      mac = "3c:6a:9d:14:cd:fd";
      ip = "192.168.20.240";
    };
    philips-hue = {
      mac = "00:17:88:6b:d0:9b";
      ip = "192.168.20.241";
    };
    tahoma-bridge = {
      mac = "f4:3c:3b:e7:1c:3e";
      ip = "192.168.20.242";
    };
  };

  config.networking.hosts =
    let
      toHost =
        n: v:
        lib.attrsets.nameValuePair v.ip [
          n
          "${n}.local"
        ];
    in
    lib.attrsets.mapAttrs' toHost config.${namespace}.networkmap;
}
