{
  config,
  lib,
  namespace,
  ...
}:
{
  options.${namespace}.networkmap = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          mac = lib.mkOption {
            type = lib.types.strMatching "([[:xdigit:]]{2}:){5}[[:xdigit:]]{2}";
            description = "MAC address";
            default = null;
          };
          ip = lib.mkOption {
            type = lib.types.strMatching "192\.168\.1\.[[:digit:]]{1,3}";
            description = "IPv4 local address";
            default = null;
          };
        };
      }
    );
    description = "Networkmap";
  };

  config.${namespace}.networkmap = {
    usw-mini = {
      mac = "74:ac:b9:ab:b7:34";
      ip = "192.168.1.2";
    };
    unifi-ap-ac-prod = {
      mac = "f4:92:bf:23:42:c7";
      ip = "192.168.1.3";
    };
    unifi-cloudkey = {
      mac = "74:ac:b9:16:73:33";
      ip = "192.168.1.4";
    };
    # jonsnow-admin0 =
    # {
    #   # this is the admin0 port
    #   mac = "a8:a1:59:92:8f:9d";
    #   ip = "192.168.1.5";
    # }

    chromecastgoogletv = {
      mac = "14:c1:4e:01:b3:21";
      ip = "192.168.1.10";
    };
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
      mac = "10:e7:c6:34:de:74";
      ip = "192.168.1.243";
    };

    elgato-keylight = {
      mac = "3c:6a:9d:14:cd:fd";
      ip = "192.168.1.240";
    };
    philips-hue = {
      mac = "00:17:88:6b:d0:9b";
      ip = "192.168.1.241";
    };
    tahoma-bridge = {
      mac = "f4:3c:3b:e7:1c:3e";
      ip = "192.168.1.242";
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
